"""
MESS: Macro Energy Synthesis System
Copyright (C) 2022, College of Engineering, Peking University

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"""

@doc raw"""

"""
function load_synfuels_subzones(synfuels_settings::Dict, inputs::Dict)

    print_and_log(synfuels_settings, "i", "Changing Synfuels Sector Inputs to Subzone Version")

    power_inputs = inputs["PowerInputs"]
    synfuels_inputs = inputs["SynfuelsInputs"]

    ## Generators zone to subzone
    dfGen = synfuels_inputs["dfGen"]
    SubZones = power_inputs["SubZones"]
    if nrow(dfGen) != length(SubZones)
        dfGen = filter(row -> any(occursin.(row.Zone, SubZones)), dfGen)
        dfs = []
        for row in eachrow(dfGen)
            df = repeat(DataFrame(row), sum(occursin.(row.Zone, SubZones)))
            df[!, :Zone] = SubZones[occursin.(row.Zone, SubZones)]
            push!(dfs, df)
        end
        dfGen = reduce(vcat, dfs)
    else
        dfGen[!, :Zone] = SubZones
    end
    dfGen[!, :Resource] = string.("Synthesis ", dfGen[!, :Zone])
    dfGen[!, :R_ID] = 1:size(collect(skipmissing(dfGen[!, 1])), 1)
    synfuels_inputs["dfGen"] = dfGen
    synfuels_inputs["G"] = size(collect(skipmissing(dfGen[!, :R_ID])), 1)
    synfuels_inputs["GenResources"] = collect(skipmissing(dfGen[!, :Resource]))

    GenCommit = synfuels_settings["GenCommit"]
    if GenCommit >= 1
        synfuels_inputs["THERM_COMMIT"] = dfGen[dfGen.THERM .== 1, :R_ID]
        synfuels_inputs["THERM_NO_COMMIT"] = dfGen[dfGen.THERM .== 2, :R_ID]
        ## Set of synfuels generators as electrolysers as hydrogen source
        synfuels_inputs["ELE_COMMIT"] = dfGen[dfGen.ELE .== 1, :R_ID]
        synfuels_inputs["ELE_NO_COMMIT"] = dfGen[dfGen.ELE .== 2, :R_ID]
    else
        synfuels_inputs["THERM_COMMIT"] = Int64[]
        synfuels_inputs["THERM_NO_COMMIT"] =
            sort(union(dfGen[dfGen.THERM .== 1, :R_ID], dfGen[dfGen.THERM .== 2, :R_ID]))
        ## Set of synfuels generators as electrolysers as hydrogen source
        synfuels_inputs["ELE_COMMIT"] = Int64[]
        synfuels_inputs["ELE_NO_COMMIT"] =
            sort(union(dfGen[dfGen.ELE .== 1, :R_ID], dfGen[dfGen.ELE .== 2, :R_ID]))
    end
    synfuels_inputs["THERM"] =
        sort(union(synfuels_inputs["THERM_COMMIT"], synfuels_inputs["THERM_NO_COMMIT"]))
    synfuels_inputs["ELE"] =
        sort(union(synfuels_inputs["ELE_COMMIT"], synfuels_inputs["ELE_NO_COMMIT"]))

    ## For now, the only resources eligible for UC are themal resources
    synfuels_inputs["COMMIT"] =
        sort(union(synfuels_inputs["THERM_COMMIT"], synfuels_inputs["ELE_COMMIT"]))
    synfuels_inputs["NO_COMMIT"] =
        sort(union(synfuels_inputs["THERM_NO_COMMIT"], synfuels_inputs["ELE_NO_COMMIT"]))

    G = synfuels_inputs["G"]
    GenerationExpansion = synfuels_settings["GenerationExpansion"]
    ## Set of all resources eligible for new capacity
    if GenerationExpansion == -1
        synfuels_inputs["NEW_GEN_CAP"] = Int64[]
    elseif GenerationExpansion == 0
        synfuels_inputs["NEW_GEN_CAP"] = dfGen[dfGen.New_Build .== 1, :R_ID]
    elseif GenerationExpansion == 1
        synfuels_inputs["NEW_GEN_CAP"] = 1:G
    end
    synfuels_inputs["NEW_GEN_CAP"] = intersect(
        synfuels_inputs["NEW_GEN_CAP"],
        union(
            dfGen[dfGen.Max_Cap_tonne_per_hr .== -1, :R_ID],
            intersect(
                dfGen[dfGen.Max_Cap_tonne_per_hr .!= -1, :R_ID],
                dfGen[dfGen.Max_Cap_tonne_per_hr .- dfGen.Existing_Cap_tonne_per_hr .> 0, :R_ID],
            ),
        ),
    )
    ## Set of all resources eligible for capacity retirements
    synfuels_inputs["RET_GEN_CAP"] = intersect(
        dfGen[dfGen.Retirement .== 1, :R_ID],
        dfGen[dfGen.Existing_Cap_tonne_per_hr .> 0, :R_ID],
    )

    synfuels_inputs["P_Max"] = ones(Float64, (G, inputs["T"]))

    ## Storage zone to subzone
    if synfuels_settings["ModelStorage"] == 1
        dfSto = synfuels_inputs["dfSto"]
        if nrow(dfSto) != length(SubZones)

            dfSto = filter(row -> any(occursin.(row.Zone, SubZones)), dfSto)
            dfs = []
            for row in eachrow(dfSto)
                df = repeat(DataFrame(row), sum(occursin.(row.Zone, SubZones)))
                df[!, :Zone] = SubZones[occursin.(row.Zone, SubZones)]
                push!(dfs, df)
            end
            dfSto = reduce(vcat, dfs)
        else
            dfSto[!, :Zone] = SubZones
        end
        dfSto[!, :Resource] = string.("Tank ", dfSto[!, :Zone])
        dfSto[!, :R_ID] = 1:size(collect(skipmissing(dfSto[!, 1])), 1)
        synfuels_inputs["dfSto"] = dfSto
        synfuels_inputs["S"] = size(collect(skipmissing(dfSto[!, :R_ID])), 1)

        S = synfuels_inputs["S"]
        StorageExpansion = synfuels_settings["StorageExpansion"]
        ## Set of all storage resources eligible for new energy capacity
        if StorageExpansion == -1
            synfuels_inputs["NEW_STO_CAP"] = Int64[]
        elseif StorageExpansion == 0
            synfuels_inputs["NEW_STO_CAP"] = dfSto[dfSto.New_Build .== 1, :R_ID]
        elseif StorageExpansion == 1
            synfuels_inputs["NEW_STO_CAP"] = 1:S
        end
        synfuels_inputs["NEW_STO_CAP"] = intersect(
            synfuels_inputs["NEW_STO_CAP"],
            union(
                dfSto[dfSto.Max_Ene_Cap_tonne .== -1, :R_ID],
                intersect(
                    dfSto[dfSto.Max_Ene_Cap_tonne .!= 1, :R_ID],
                    dfSto[dfSto.Max_Ene_Cap_tonne .- dfSto.Existing_Ene_Cap_tonne .> 0, :R_ID],
                ),
            ),
        )
        ## Set of all storage resources eligible for energy capacity retirements
        synfuels_inputs["RET_STO_CAP"] = intersect(
            dfSto[dfSto.Retirement .== 1, :R_ID],
            dfSto[dfSto.Existing_Ene_Cap_tonne .> 0, :R_ID],
        )
        synfuels_inputs["StoResources"] = collect(skipmissing(dfSto[!, :Resource]))
    end

    ## Demand zone to subzone
    synfuels_inputs["D"] = zeros(Float64, (length(power_inputs["SubZones"]), inputs["T"]))

    inputs["SynfuelsInputs"] = synfuels_inputs

    return inputs
end
