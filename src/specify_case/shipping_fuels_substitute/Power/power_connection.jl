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
function power_connection(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Applying Power Connection Patch")

    power_settings = settings["PowerSettings"]

    T = inputs["T"]
    Zones = inputs["Zones"]

    power_inputs = inputs["PowerInputs"]
    dfGen = power_inputs["dfGen"]
    G = power_inputs["G"]

    ### Expressions ###
    ## Convergence line costs
    if in("Hub_Longitude", names(dfGen)) && in("Hub_Latitude", names(dfGen))
        if haskey(inputs, "Connection_Costs_per_MW_per_km")
            @expression(
                MESS,
                ePObjNetworkConvergenceCell[g in 1:G],
                inputs["Connection_Costs_per_MW_per_km"] *
                MESS[:ePGenCap][g] *
                dfGen[!, :Hub_Distance][g] *
                0.1067
            )
        elseif haskey(inputs, "Connection_Costs_per_MW")
            @expression(
                MESS,
                ePObjNetworkConvergenceCell[g in 1:G],
                inputs["Connection_Costs_per_MW"] * MESS[:ePGenCap][g] * 0.1067
            )
        elseif haskey(inputs, "Connection_Costs_per_km")
            @expression(
                MESS,
                ePObjNetworkConvergenceCell[g in 1:G],
                AffExpr(inputs["Connection_Costs_per_km"] * dfGen[!, :Hub_Distance][g] * 0.1067)
            )
        end
        @expression(
            MESS,
            ePObjNetworkConvergence,
            sum(MESS[:ePObjNetworkConvergenceCell][g] for g in 1:G; init = 0.0)
        )
    end

    ## Connection line costs
    @expression(MESS, ePObjNetworkConnection, MESS[:ePObjNetworkConvergence])

    ## Delivery line costs with additional calculation based on distance
    if inputs["Case"] == "Offshore_Port"
        dfLine = power_inputs["dfLine"]
        HUB_LINES = power_inputs["HUB_LINES"]
        @expression(
            MESS,
            ePObjNetworkDelivery[l in HUB_LINES],
            inputs["Delivery_Costs_per_km"] *
            1.61 *
            dfLine[!, :Distance_miles][l] *
            MESS[:ePLineCap][l] *
            dfLine[!, :AF][l]
        )
        add_to_expression!(
            MESS[:ePObjNetworkConnection],
            sum(MESS[:ePObjNetworkDelivery][l] for l in HUB_LINES; init = 0.0),
        )
    end

    ## Add line costs to objective function
    add_to_expression!(MESS[:ePObj], MESS[:ePObjNetworkConnection])
    add_to_expression!(MESS[:eObj], MESS[:ePObjNetworkConnection])
    ### End Expressions ###

    ### Constraints ###
    # if inputs["Case"] == "Offshore_Port"
    #     L = power_inputs["L"]
    #     dfLine = power_inputs["dfLine"]
    #     SubZones = power_inputs["SubZones"]
    #     HUB_LINES = power_inputs["HUB_LINES"]

    #     ## Sell back wind electricity curtailment
    #     if haskey(settings, "Wind_Electricity_Price") && settings["Wind_Electricity_Price"] > 0.0
    #         ## Transmission line capacity must exceed necessary power and curtailed power consumption
    #         @expression(
    #             MESS,
    #             ePLineFlowCurtailment[l in 1:L, t in 1:T],
    #             if l in HUB_LINES
    #                 MESS[:ePAvailableVRESubZonal][dfLine[dfLine.L_ID .== l, :Start_SubZone][1], t] -
    #                 MESS[:ePGenerationSubZonal][dfLine[dfLine.L_ID .== l, :Start_SubZone][1], t]
    #             else
    #                 0
    #             end
    #         )
    #         delete.(MESS, MESS[:cMaxFlowPos])
    #         unregister(MESS, :cMaxFlowPos)
    #         delete.(MESS, MESS[:cMaxFlowNeg])
    #         unregister(MESS, :cMaxFlowNeg)
    #         ## Maximum power flows, power flow on each transmission line cannot exceed maximum capacity of the line at any hour "t"
    #         @constraints(
    #             MESS,
    #             begin
    #                 cMaxFlowPos[l in 1:L, t in 1:T],
    #                 MESS[:vPLineFlow][l, t] + MESS[:ePLineFlowCurtailment][l, t] <=
    #                 MESS[:ePLineCap][l]
    #                 cMaxFlowNeg[l in 1:L, t in 1:T],
    #                 MESS[:vPLineFlow][l, t] + MESS[:ePLineFlowCurtailment][l, t] >=
    #                 -MESS[:ePLineCap][l]
    #             end
    #         )
    #     end
    # end
    ### End Constraints ###

    return MESS
end
