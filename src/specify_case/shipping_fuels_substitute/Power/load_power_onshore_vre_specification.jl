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
function load_power_onshore_vre_specification(power_settings::Dict, inputs::Dict)

    print_and_log(
        power_settings,
        "i",
        "Loading Onshore Wind Turbine/Solar Panels Specification Data",
    )

    if haskey(inputs, "BOP")
        BOP = inputs["BOP"]
    end

    ## Get power sector inputs
    power_inputs = inputs["PowerInputs"]
    dfGen = power_inputs["dfGen"]
    Onshore_PV = power_inputs["Onshore_PV"]
    Onshore_WT = power_inputs["Onshore_WT"]

    ## The PV module's BOP is 66.67% relative to the module costs
    ## The onshore WT's BOP is 76.64% relative to the turbine costs
    #! Offshore WT's BOP is calculated for all generators at first and then onshore WT and PV will override it
    dfGen = transform(
        dfGen,
        [:R_ID, :Inv_Cost_per_MW, :BOP_Cost_per_MW] =>
            ByRow((R, INV, BC) -> R in Onshore_PV ? 1.588 * BOP * INV + 0.647 * INV : BC) =>
                :BOP_Cost_per_MW,
    )

    dfGen = transform(
        dfGen,
        [:R_ID, :Inv_Cost_per_MW, :BOP_Cost_per_MW] =>
            ByRow((R, INV, BC) -> R in Onshore_WT ? 0.7664 * BOP * INV : BC) =>
                :BOP_Cost_per_MW,
    )

    dfGen[!, :BOP_OM_Cost_per_MW] =
        round.(dfGen[!, :BOP_Cost_per_MW] .* dfGen[!, :Fixed_OM_Cost_Percentage]; sigdigits = 6)

    ## Methanol transport unit costs per tonne per km
    Methanol_Land_Transport_Costs_per_km_per_ton =
        power_settings["Methanol_Land_Transport_Costs_per_km_per_ton"]

    dfGen = transform(
        dfGen,
        [
            :R_ID,
            :Distance,
            :Electricity_to_Methanol_Rate_MWh_per_tonne,
            :Methanol_Transport_Costs_per_MWh,
        ] =>
            ByRow(
                (R, D, E2M, MTC) -> (
                    R in union(Onshore_PV, Onshore_WT) ?
                    1.609 * D * Methanol_Land_Transport_Costs_per_km_per_ton / E2M : MTC
                ),
            ) => :Methanol_Transport_Costs_per_MWh,
    )

    power_inputs["dfGen"] = dfGen
    inputs["PowerInputs"] = power_inputs

    return inputs
end
