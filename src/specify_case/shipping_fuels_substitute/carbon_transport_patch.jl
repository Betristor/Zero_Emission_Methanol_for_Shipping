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
function carbon_transport_patch(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Carbon Transport Costs Patch")

    T = inputs["T"]
    weights = inputs["weights"]
    Zones = inputs["Zones"]

    ## Carbon generators inputs
    carbon_inputs = inputs["CarbonInputs"]
    dfRoute = carbon_inputs["dfRoute"]
    dfGen = carbon_inputs["dfGen"]
    G = carbon_inputs["G"]
    R = carbon_inputs["R"]

    Shipping_Demand_Emission_Capture_Percentage =
        settings["Shipping_Demand_Emission_Capture_Percentage"]

    carbon_settings = settings["CarbonSettings"]
    Carbon_Sea_Transport_Costs_per_km_per_ton =
        carbon_settings["Carbon_Sea_Transport_Costs_per_km_per_ton"]

    synfuels_settings = settings["SynfuelsSettings"]

    ### Expressions ###
    ## Carbon transport costs
    @expression(
        MESS,
        eObjCarbonTransportOGT[g in 1:G, t in 1:T],
        dfGen[!, :Carbon_Transport_Costs_per_tonne][g] *
        MESS[:vAvailableCarbon][findfirst(x -> x == dfGen[!, :Zone][g], Zones), t]
    )

    @expression(
        MESS,
        eObjCarbonTransportOG[g in 1:G],
        sum(MESS[:eObjCarbonTransportOGT][g, t] for t in 1:T; init = 0.0)
    )

    @expression(
        MESS,
        eObjCarbonTransport,
        sum(MESS[:eObjCarbonTransportOG][g] for g in 1:G; init = 0.0)
    )

    ## Add term to objective function expression
    add_to_expression!(MESS[:eObj], MESS[:eObjCarbonTransport])

    ## Carbon shipping costs
    @expression(
        MESS,
        eObjCarbonShipCosts,
        sum(
            weights[t] *
            Carbon_Sea_Transport_Costs_per_km_per_ton *
            Shipping_Demand_Emission_Capture_Percentage *
            synfuels_settings["DemandEmissionFactor"] *
            MESS[:vSShipFlux][r, d, t] *
            dfRoute[r, :Distance_km] for r in intersect(
                1:R,
                dfRoute[
                    occursin.("Port", dfRoute.Start_Zone) .&& occursin.("Port", dfRoute.End_Zone),
                    :R_ID,
                ],
            ), d in [-1, 1], t in 1:T
        )
    )

    add_to_expression!(MESS[:eObj], MESS[:eObjCarbonShipCosts])
    ## End Objective Expressions ##

    return MESS
end
