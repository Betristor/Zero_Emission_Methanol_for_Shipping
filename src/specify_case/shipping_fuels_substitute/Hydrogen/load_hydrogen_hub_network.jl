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
function load_hydrogen_hub_network(settings::Dict, inputs::Dict)

    print_and_log(settings, "i", "Loading Network Connecting Zones with Sub Zone Information")

    ## Flags
    power_settings = settings["PowerSettings"]
    hydrogen_settings = settings["HydrogenSettings"]
    NetworkExpansion = hydrogen_settings["NetworkExpansion"]

    ## Number of zones in the network
    Z = inputs["Z"]
    Zones = inputs["Zones"]

    ## Get hydrogen sector inputs
    hydrogen_inputs = inputs["HydrogenInputs"]
    dfGen = hydrogen_inputs["dfGen"]
    dfPipe = hydrogen_inputs["dfPipe"]

    ## Get power sector inputs
    power_inputs = inputs["PowerInputs"]
    SubZones = power_inputs["SubZones"]
    dfPGen = power_inputs["dfGen"]

    ## Get unique generator dataframe for pipe mapping
    temp = unique(dfPGen, Symbol(power_settings["SubZoneKey"]))
    dfPipe_Exclude = filter(
        row -> !(occursin.("Hub", row.Start_Zone) && occursin.("Port", row.End_Zone)),
        dfPipe,
    )
    dfPipe_Include = filter(
        row -> (
            occursin.("Hub", row.Start_Zone) &&
            occursin.("Port", row.End_Zone) &&
            split(row.Start_Zone, "_")[1] == split(row.End_Zone, "_")[1]
        ),
        dfPipe,
    )
    ## Create multi pipes from sub zones to end zone for hub modeling - pipe distance in miles
    dfs = []
    for z in findall(x -> any(occursin.(x, SubZones)), Zones)
        #! Nearly hard-coded since in this case pipes are from location where wind
        #! turbines are located to ports
        dfPipe_Selected = filter(row -> row.Start_Zone == Zones[z], dfPipe_Include)
        ## Add sub zone column
        szs = SubZones[occursin.(Zones[z], SubZones)]
        df = repeat(dfPipe_Selected, inner = length(szs))
        df[!, :Start_SubZone] = szs
        ## Change pipe distance column in miles
        dis = []
        for sz in szs
            push!(dis, first(temp[temp.Zone .== sz, :Line_Distance]) * 0.6214)
        end
        df[!, :Pipe_Length_miles] = dis
        push!(dfs, df)
        ## Connection pipes connecting wind turbines and hubs
        dfPipe = reduce(vcat, dfs)
    end
    dfPipe_Exclude[!, :Start_SubZone] = dfPipe_Exclude[!, :Start_Zone]
    push!(dfs, dfPipe_Exclude)
    dfPipe = reduce(vcat, dfs)
    dfPipe[!, :Start_Zone] = dfPipe[!, :Start_SubZone]

    ## Add a new column to the dfPipe dataframe to store the pipe index
    dfPipe[!, :P_ID] = 1:size(dfPipe, 1)

    ## Number of pipelines in the network
    hydrogen_inputs["P"] = size(collect(skipmissing(dfPipe[!, :P_ID])), 1)
    P = hydrogen_inputs["P"]

    dfPipe[!, :Booster_Stations_Number] =
        floor.(Int64, dfPipe[!, :Pipe_Length_miles] ./ dfPipe[!, :Distance_bw_Booster_miles])

    ## Store pipeline dataframe for later use in model
    hydrogen_inputs["dfPipe"] = dfPipe

    ## Expansional pipelines
    if NetworkExpansion == -1
        hydrogen_inputs["NEW_PIPES"] = Inf64[]
    elseif NetworkExpansion == 0
        hydrogen_inputs["NEW_PIPES"] = dfPipe[dfPipe.New_Build .== 1, :P_ID]
    elseif NetworkExpansion == 1
        hydrogen_inputs["NEW_PIPES"] = 1:P
    end
    hydrogen_inputs["NEW_PIPES"] = intersect(
        hydrogen_inputs["NEW_PIPES"],
        union(
            dfPipe[dfPipe.Max_Pipe_Number .== -1, :P_ID],
            intersect(
                dfPipe[dfPipe.Max_Pipe_Number .!= -1, :P_ID],
                dfPipe[dfPipe.Max_Pipe_Number .- dfPipe.Existing_Pipe_Number .> 0, :P_ID],
            ),
        ),
    )

    ## Store DataFrame of pipe input data for use in model
    inputs["HydrogenInputs"] = hydrogen_inputs

    return inputs
end
