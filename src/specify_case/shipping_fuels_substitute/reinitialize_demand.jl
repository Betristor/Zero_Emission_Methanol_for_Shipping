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
function reinitialize_demand(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Reinitialize Sector Demand Expression")

    Z = inputs["Z"]
    Zones = inputs["Zones"]
    T = inputs["T"]

    shipping_demand = inputs["Shipping_Demand"]

    ## Potential shipping demand substitue base value - hard-coded
    diesel_kg_per_hkm = 3.6936 ## Desial consumption in kg per 100 km
    methanol_kg_per_hkm = 7.28864 ## Methanol consumption in kg per 100 km

    SDMER = methanol_kg_per_hkm / diesel_kg_per_hkm

    ## Potential shipping demand substitue base value - inputs
    if haskey(settings, "Shipping_Demand_Methanol_Equivalence_Ratio")
        Shipping_Demand_Methanol_Equivalence_Ratio =
            settings["Shipping_Demand_Methanol_Equivalence_Ratio"]
        SDMER = Shipping_Demand_Methanol_Equivalence_Ratio
        print_and_log(settings, "i", "Inputs Fuel Equivalence Ratio for Methanol is: $SDMER")
    else
        print_and_log(settings, "i", "Default Fuel Equivalence Ratio for Methanol is: $SDMER")
    end

    total_methanol_demand = round.(inputs["Total_Shipping_Demand"] .* SDMER; sigdigits = 4)
    print_and_log(
        settings,
        "i",
        "Total Methanol Demand from Fuel Replacement is $(total_methanol_demand)",
    )

    ## Synfuels sector demand expression
    if settings["ModelSynfuels"] == 1
        synfuels_settings = settings["SynfuelsSettings"]
        synfuels_inputs = inputs["SynfuelsInputs"]

        ## Synfuels demand from shipping
        if settings["YearlyBalance"] == 1
            @expression(MESS, methanol_demand[z in 1:Z, t in 1:T], MESS[:eSBalance][z, t])
            @expression(MESS, total_methanol_demand[z in 1:length(inputs["DZones"])], total_methanol_demand[z])
        else
            @expression(MESS, methanol_demand[z in 1:Z, t in 1:T], shipping_demand[z, t] * SDMER)
        end
        add_to_expression!.(MESS[:eSDemandAddition], MESS[:methanol_demand])

        @expression(MESS, eSDemand[z in 1:Z, t in 1:T], AffExpr(synfuels_inputs["D"][z, t]))

        ## Add additional demand
        add_to_expression!.(MESS[:eSDemand], MESS[:eSDemandAddition])
        if synfuels_settings["AllowNse"] == 1
            ## Minus non served demand if modeled
            add_to_expression!.(MESS[:eSDemand], -MESS[:eSBalanceNse])
        end

        ## Refueling costs
        @expression(
            MESS,
            eObjRefuelingOZT[z in 1:Z, t in 1:T],
            settings["Refueling_Costs"] * MESS[:eSDemand][z, t]
        )
        @expression(
            MESS,
            eObjRefuelingOZ[z in 1:Z],
            sum(MESS[:eObjRefuelingOZT][z, t] for t in 1:T; init = 0.0)
        )
        @expression(
            MESS,
            eObjRefuelingOT[t in 1:T],
            sum(MESS[:eObjRefuelingOZT][z, t] for z in 1:Z; init = 0.0)
        )
        @expression(MESS, eObjRefueling, sum(MESS[:eObjRefuelingOZ][z] for z in 1:Z; init = 0.0))

        ## Add term to objective function expression
        add_to_expression!(MESS[:eObj], MESS[:eObjRefueling])
    end

    return MESS
end
