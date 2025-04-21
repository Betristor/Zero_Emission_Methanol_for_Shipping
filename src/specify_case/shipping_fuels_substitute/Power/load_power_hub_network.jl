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
function load_power_hub_network(power_settings::Dict, inputs::Dict)

    print_and_log(power_settings, "i", "Loading Network Connecting Zones with Sub Zone Information")

    ## Flags
    NetworkExpansion = power_settings["NetworkExpansion"]
    LineLossSegments = power_settings["LineLossSegments"]

    ## Number of zones in the network
    Z = inputs["Z"]
    Zones = inputs["Zones"]

    ## Get power sector inputs
    power_inputs = inputs["PowerInputs"]
    dfGen = power_inputs["dfGen"]
    dfLine = power_inputs["dfLine"]
    SubZones = power_inputs["SubZones"]

    ## Get unique generator dataframe for line mapping
    temp = unique(dfGen, Symbol(power_settings["SubZoneKey"]))
    dfLine_Exclude = filter(
        row -> !(occursin.("Hub", row.Start_Zone) && occursin.("Port", row.End_Zone)),
        dfLine,
    )
    dfLine_Include = filter(
        row -> (
            occursin.("Hub", row.Start_Zone) &&
            occursin.("Port", row.End_Zone) &&
            split(row.Start_Zone, "_")[1] == split(row.End_Zone, "_")[1]
        ),
        dfLine,
    )
    ## Create multi lines from sub zones to end zone for hub modeling - line distance in miles
    dfs = []
    for z in findall(x -> any(occursin.(x, SubZones)), Zones)
        #! Nearly hard-coded since in this case lines are from location where wind
        #! turbines are located to ports
        dfLine_Selected = filter(row -> row.Start_Zone == Zones[z], dfLine_Include)
        ## Add sub zone column
        szs = SubZones[occursin.(Zones[z], SubZones)]
        df = repeat(dfLine_Selected, inner = length(szs))
        df[!, :Start_SubZone] = szs
        ## Change line distance column in miles
        df[!, :Distance_miles] = temp[temp.Zone .== Zones[z], :Line_Distance] * 0.6214
        df[!, :Path_Name] = string.(df[!, :Start_SubZone], " -> ", df[!, :End_Zone])
        push!(dfs, df)
        ## Connection lines connecting wind turbines and hubs
        dfLine = reduce(vcat, dfs)
        HUB_LINES = 1:size(dfLine, 1)
        power_inputs["HUB_LINES"] = HUB_LINES
    end
    dfLine_Exclude[!, :Start_SubZone] = dfLine_Exclude[!, :Start_Zone]
    push!(dfs, dfLine_Exclude)
    dfLine = reduce(vcat, dfs)
    dfLine[!, :Start_Zone] = dfLine[!, :Start_SubZone]

    ## Add a new column to the dfLine dataframe to store the line index
    dfLine[!, :L_ID] = 1:size(dfLine, 1)
    ## Number of lines in the network
    power_inputs["L"] = size(collect(skipmissing(dfLine[!, :L_ID])), 1)

    power_inputs["dfLine"] = dfLine

    L = power_inputs["L"]
    ## Maximum possible flow after reinforcement for use in linear segments of piecewise approximation
    dfLine[!, :Trans_Max_Possible] = zeros(Float64, L)

    if NetworkExpansion == -1
        power_inputs["NEW_LINES"] = Int64[]
        dfLine[!, :Line_Max_Reinforcement_MW] .= 0
    elseif NetworkExpansion == 0
        power_inputs["NEW_LINES"] = intersect(
            dfLine[dfLine.New_Build .== 1, :L_ID],
            dfLine[dfLine.Line_Max_Reinforcement_MW .> 0, :L_ID],
        )
    elseif NetworkExpansion == 1
        power_inputs["NEW_LINES"] =
            intersect(1:L, dfLine[dfLine.Line_Max_Reinforcement_MW .> 0, :L_ID])
    end
    power_inputs["NEW_LINES"] = intersect(
        power_inputs["NEW_LINES"],
        union(
            dfLine[dfLine.Max_Line_Cap_MW .== -1, :L_ID],
            intersect(
                dfLine[dfLine.Max_Line_Cap_MW .!= -1, :L_ID],
                dfLine[dfLine.Max_Line_Cap_MW .- dfLine.Existing_Line_Cap_MW .> 0, :L_ID],
            ),
        ),
    )

    for l in 1:L
        if dfLine[!, :Line_Max_Reinforcement_MW][l] > 0
            dfLine[!, :Trans_Max_Possible][l] =
                dfLine[!, :Max_Line_Cap_MW][l] + dfLine[!, :Line_Max_Reinforcement_MW][l]
        else
            dfLine[!, :Trans_Max_Possible][l] = dfLine[!, :Max_Line_Cap_MW][l]
        end
    end

    ## Transmission line (between zone) loss coefficient (resistance/voltage^2)
    dfLine[!, :Trans_Loss_Coef] = zeros(Float64, L)
    for l in 1:L
        ## For cases with only one segment
        if LineLossSegments == 1
            dfLine[!, :Trans_Loss_Coef][l] = dfLine[!, :Line_Loss_Percentage][l]
        elseif LineLossSegments >= 2
            dfLine[!, :Trans_Loss_Coef][l] =
                (dfLine[!, :Line_Resistance_ohms][l] / 10^6) /
                (dfLine[!, :Line_Voltage_kV][l] / 10^3)^2 # 1/MW
        end
    end

    ## Store DataFrame of line input data for use in model
    inputs["PowerInputs"] = power_inputs

    ## Sets and indices for transmission losses and expansion
    power_inputs["TRANS_LOSS_SEGS"] = LineLossSegments # Number of segments used in piecewise linear approximations quadratic loss functions
    power_inputs["LOSS_LINES"] = dfLine[dfLine.Trans_Loss_Coef .!= 0, :L_ID] # Lines for which loss coefficients apply (are non-zero);

    return inputs
end
