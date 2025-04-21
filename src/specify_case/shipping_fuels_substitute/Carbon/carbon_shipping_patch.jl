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
function carbon_shipping_patch(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Applying Carbon Shipping Patch to Carbon Balance")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    carbon_inputs = inputs["CarbonInputs"]
    dfRoute = carbon_inputs["dfRoute"]

    Ship_map = carbon_inputs["Ship_map"]
    SHIP_ZONES = carbon_inputs["SHIP_ZONES"]

    R = carbon_inputs["R"]

    ### Variables ###
    ## Ship flow volume [tonne] through at time "t" on zone "z"
    @variable(MESS, vCShipFlow[z in SHIP_ZONES, t = 1:T])
    @variable(MESS, vCShipFlux[r in 1:R, d in [-1, 1], t = 1:T] >= 0)

    ### Expressions ###
    ## Objective Expressions ##
    @expression(
        MESS,
        eCObjCarbonShipCosts,
        sum(
            weights[t] *
            (
                settings["Shipping_Carbon_Costs_per_ton_per_km"] * dfRoute[r, :Distance_km] +
                settings["Shipping_Carbon_Costs_per_ton"]
            ) *
            MESS[:vCShipFlux][r, d, t] for r in 1:R, d in [-1, 1], t in 1:T
        )
    )

    add_to_expression!(MESS[:eCObj], MESS[:eCObjCarbonShipCosts])
    add_to_expression!(MESS[:eObj], MESS[:eCObjCarbonShipCosts])
    ## End Objective Expressions ##

    ## Balance Expressions ##
    ## Synfuels balance
    @expression(
        MESS,
        eCBalanceShipZonalFlow[z = 1:Z, t = 1:T],
        begin
            if Zones[z] in SHIP_ZONES
                MESS[:vCShipFlow][Zones[z], t]
            else
                0
            end
        end
    )
    add_to_expression!.(MESS[:eCBalance], MESS[:eCBalanceShipZonalFlow])
    add_to_expression!.(MESS[:eCTransmission], MESS[:eCBalanceShipZonalFlow])
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###
    @constraint(
        MESS,
        cCShipFlow[z in SHIP_ZONES, t = 1:T],
        MESS[:vCShipFlow][z, t] ==
        -sum(
            Ship_map[(Ship_map.Zone .== z) .& (Ship_map.route_no .== r), :d][1] *
            (MESS[:vCShipFlux][r, 1, t] - MESS[:vCShipFlux][r, -1, t]) for
            r in Ship_map[Ship_map.Zone .== z, :route_no]
        ),
    )
    ### End Constraints ###

    return MESS
end
