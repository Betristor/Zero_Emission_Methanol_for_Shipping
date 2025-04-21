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
function reinitialize_emission(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Making Usage of Carbon Emitted from Substitution Demand")

    ## Demand emission capture percantage
    Shipping_Demand_Emission_Capture_Percentage =
        settings["Shipping_Demand_Emission_Capture_Percentage"]
    Shipping_Demand_Emission_CapSto_Cost = settings["Shipping_Demand_Emission_CapSto_Cost"]

    Z = inputs["Z"]
    Zones = inputs["Zones"]

    T = inputs["T"]

    synfuels_settings = settings["SynfuelsSettings"]

    ### Expressions ###
    ## Synfuels sector emission from demand
    @expression(
        MESS,
        eSEmissionsByDemand[z in 1:Z, t in 1:T],
        synfuels_settings["DemandEmissionFactor"] * MESS[:eSDemand][z, t]
    )

    if inputs["Case"] == "Offshore_Port"
        mask = occursin.("Port", Zones)
    else
        mask = ones(Z)
    end

    ## Synfuels sector emission from substitution methanol demand
    @expression(
        MESS,
        eSEmissionsByMethanolDemand[z in 1:Z, t in 1:T],
        mask[z] *
        Shipping_Demand_Emission_Capture_Percentage *
        synfuels_settings["DemandEmissionFactor"] *
        MESS[:methanol_demand][z, t]
    )

    ## Available carbon emission from methanol demand
    @variable(MESS, vAvailableCarbon[z in 1:Z, t in 1:T] >= 0)
    @constraint(
        MESS,
        cAvailableCarbon[z in 1:Z, t in 1:T],
        MESS[:vAvailableCarbon][z, t] <= MESS[:eSEmissionsByMethanolDemand][z, t]
    )

    ## Add demand emission to carbon balance since these emitted carbon is utilized
    add_to_expression!.(MESS[:eCBalance], MESS[:vAvailableCarbon])

    ## Add uncaped demand emission to total emission
    add_to_expression!.(
        MESS[:eSEmissions],
        MESS[:eSEmissionsByMethanolDemand] .- MESS[:vAvailableCarbon],
    )
    add_to_expression!.(
        MESS[:eEmissions],
        MESS[:eSEmissionsByMethanolDemand] .- MESS[:vAvailableCarbon],
    )

    ## Objective Expressions ##
    ## Onboard carbon capture and storage costs
    @expression(
        MESS,
        eObjShippingCarbonCapStoOZT[z in 1:Z, t in 1:T],
        Shipping_Demand_Emission_CapSto_Cost * MESS[:vAvailableCarbon][z, t]
    )
    @expression(
        MESS,
        eObjShippingCarbonCapStoOZ[z in 1:Z],
        sum(MESS[:eObjShippingCarbonCapStoOZT][z, t] for t in 1:T)
    )
    @expression(
        MESS,
        eObjShippingCarbonCapStoOT[t in 1:T],
        sum(MESS[:eObjShippingCarbonCapStoOZT][z, t] for z in 1:Z)
    )
    @expression(
        MESS,
        eObjShippingCarbonCapSto,
        sum(MESS[:eObjShippingCarbonCapStoOZ][z] for z in 1:Z)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eObj], MESS[:eObjShippingCarbonCapSto])

    ## Port unloaded carbon transport costs in unit calculation
    if inputs["Case"] == "Offshore_Hub"
        Refueling_Carbon_Transport_Costs_Slope_per_km_per_tonne =
            settings["Refueling_Carbon_Transport_Costs_Slope_per_km_per_tonne"]
        Refueling_Carbon_Transport_Costs_Intercept_per_tonne =
            settings["Refueling_Carbon_Transport_Costs_Intercept_per_tonne"]
        Hub_Port_Distance_km = settings["Hub_Port_Distance_km"]
        @expression(
            MESS,
            eObjShippingCarbonTransportOZT[z in 1:Z, t in 1:T],
            (
                Refueling_Carbon_Transport_Costs_Slope_per_km_per_tonne * Hub_Port_Distance_km +
                Refueling_Carbon_Transport_Costs_Intercept_per_tonne
            ) * MESS[:vAvailableCarbon][z, t]
        )
        @expression(
            MESS,
            eObjShippingCarbonTransportOZ[z in 1:Z],
            sum(MESS[:eObjShippingCarbonTransportOZT][z, t] for t in 1:T)
        )
        @expression(
            MESS,
            eObjShippingCarbonTransportOT[t in 1:T],
            sum(MESS[:eObjShippingCarbonTransportOZT][z, t] for z in 1:Z)
        )
        @expression(
            MESS,
            eObjShippingCarbonTransport,
            sum(MESS[:eObjShippingCarbonTransportOZ][z] for z in 1:Z)
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:eObj], MESS[:eObjShippingCarbonTransport])
    end

    ### End Expressions ###

    return MESS
end
