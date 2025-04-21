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
function write_power_transmission_lcoe(settings::Dict, inputs::Dict, MESS::Model)

    path = settings["SavePath"]
    power_settings = settings["PowerSettings"]
    IncludeExistingNetwork = power_settings["IncludeExistingNetwork"]

    power_inputs = inputs["PowerInputs"]
    dfLine = power_inputs["dfLine"]
    NEW_LINES = power_inputs["NEW_LINES"]

    ## Transmission line dataframe
    dfLCOE = DataFrame(
        LineName = string.(dfLine[!, :Path_Name]),
        StartZone = string.(dfLine[!, :Start_Zone]),
        EndZone = string.(dfLine[!, :End_Zone]),
    )
    dfTotal = DataFrame(LineName = "Sum", StartZone = "Sum", EndZone = "Sum")

    ## Fix costs - investment costs
    Exp = zeros(size(NEW_LINES))
    for l in NEW_LINES
        Exp[l] = value.(MESS[:ePObjNetworkExpOL][l])
    end
    dfLCOE[!, :ExpCosts] = round.(Exp; digits = 2)
    dfTotal[!, :ExpCosts] = [round(sum(Exp); digits = 2)]

    ## Fix costs - sunk investment costs
    if IncludeExistingNetwork == 1
        Exi = value.(MESS[:ePObjNetworkExistingOL])
        dfLCOE[!, :ExiCosts] = round.(Exi; digits = 2)
        dfTotal[!, :ExiCosts] = [round(sum(Exi); digits = 2)]
    end

    if inputs["Case"] == "Offshore_Port"
        HUB_LINES = power_inputs["HUB_LINES"]
        ## Fix costs - delivery line costs
        Del = zeros(size(HUB_LINES))
        for l in HUB_LINES
            Del[l] = value.(MESS[:ePObjNetworkDelivery][l])
        end
        dfLCOE[!, :DelCosts] = round.(Del; digits = 2)
        dfTotal[!, :DelCosts] = [round(sum(Del); digits = 2)]

        ## Fix costs - substation costs
        Sta = zeros(size(HUB_LINES))
        for l in HUB_LINES
            Sta[l] = value.(MESS[:ePObjSubstationLines][l])
        end
        dfLCOE[!, :StaCosts] = round.(Sta; digits = 2)
        dfTotal[!, :StaCosts] = [round(sum(Sta); digits = 2)]
    end

    dfLCOE = transform(dfLCOE, Cols(x -> contains(x, "Costs")) => (+) => :Costs)
    dfTotal[!, "Costs"] = [round(sum(dfLCOE[!, :Costs]); digits = 2)]

    ## Total transmission
    dfLCOE[!, :Transmission] =
        round.(vec(sum(abs.(value.(MESS[:vPLineFlow])); dims = 2)); digits = 2)
    dfTotal[!, :Transmission] = [round(sum(dfLCOE[!, :Transmission]); digits = 2)]

    ## LCOE calculation
    dfLCOE = transform(
        dfLCOE,
        [:Costs, :Transmission] =>
            ByRow((C, T) -> T > 0 ? round(C / T; digits = 2) : 0.0) => Symbol("LCOE (\$/MWh)"),
    )

    dfTotal[!, Symbol("LCOE (\$/MWh)")] = [
        round(
            mean(
                dfLCOE[!, Symbol("LCOE (\$/MWh)")],
                Weights(dfLCOE[!, :Transmission]),
            );
            digits = 2,
        ),
    ]

    dfLCOE = vcat(dfLCOE, dfTotal)

    CSV.write(joinpath(path, "LCOE_Transmission.csv"), dfLCOE)
end
