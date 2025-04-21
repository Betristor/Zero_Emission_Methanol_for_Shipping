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
function load_power_offshore_wt_specification(power_settings::Dict, inputs::Dict)

    print_and_log(
        power_settings,
        "i",
        "Loading Offshore Wind Turbine Specification Data including Water Depth and Foundation Types",
    )

    if haskey(inputs, "BOP")
        BOP = inputs["BOP"]
    end

    ## Get power sector inputs
    power_inputs = inputs["PowerInputs"]
    dfGen = power_inputs["dfGen"]
    Offshore_WT = power_inputs["Offshore_WT"]

    ## Decide wind turbine foundation type according to water depth
    ## If water depth exceeds 59m, then floating type should be used
    ## Basic case costs for bottom-fixed is 14.1WD+669.44 $/MW and for
    ## floating is 0.04164WD+1618.914 $/MW, the equal point is 58.987m
    dfGen =
        transform(dfGen, :Water_Depth => ByRow(x -> x > 59 ? "Floating" : "Fixed") => :Foundation)

    ## Bottom-fixed and floating wind turbines have different investment costs
    dfGen = transform(
        dfGen,
        [:Inv_Cost_per_MW, :Foundation] =>
            ByRow((INV, FD) -> FD == "Floating" ? 1.37 * INV : INV) => :Inv_Cost_per_MW,
    )

    ## Bottom-fixed and floating wind turbines have different foundation and installation costs
    ## Floating types have mooring system costs
    ## Suppose costs for bottom-fixed wind turbines are ```INV``` ($/MW) and water depth is ```WD``` (m),
    ## then the costs for floating wind turbines are ```1.37*INV``` (Katsouris 2016). Bottom-fixed type
    ## wind turbine foundation costs are related to water depth ```8*WD+30``` euro/kW (Technology
    ## Catalogue 2022). The foundation costs for floating type are fixed as ```0.81*INV```. The
    ## installation costs for bottom-fixed type are related to water depth ```2.5*WD+15``` euro/kW
    ## (Technology Catalogue 2022). The installation costs for floating type are fixed as ```0.33*INV```.
    ## Mooring system costs are considered for floating type wind turbines with a formula related to
    ## water depth ```4*[123000+1.5*(WD+410)*48+50*270]``` euro for a 10 MW system, where semi-submersible
    ## platform is considered with four chain and anchor to steady the system. And 123000 is the costs
    ## for anchors. In simplified version the formula is written as ```62472+28.8*WD``` euro/MW. Using
    ## annual average exchange rate between euro and us dollar in 2013 and CPI index, we have this as
    ## ```90324.36+41.64*WD``` in 2022 US$.

    dfGen = transform(
        dfGen,
        [:Inv_Cost_per_MW, :Water_Depth, :Foundation] =>
            ByRow(
                (INV, WD, FD) -> (
                    Foundation_Cost_per_MW = FD == "Floating" ? (0.81 * INV) : (8430 * WD + 31614),
                    Foundation_Installation_Cost_per_MW = FD == "Floating" ? (0.33 * INV) :
                                                          (2634.5 * WD + 15807),
                    Mooring_System_Cost_per_MW = FD == "Floating" ? 90324.36 + 41.64 * WD : 0,
                ),
            ) => AsTable,
    )

    ## Calculate balance of plabt costs for offshore wind turbines
    dfGen = transform(
        dfGen,
        [
            :R_ID,
            :Foundation_Cost_per_MW,
            :Foundation_Installation_Cost_per_MW,
            :Mooring_System_Cost_per_MW,
        ] =>
            ByRow((R, FC, FIC, MSC) -> (R in Offshore_WT ? BOP * (FC + FIC + MSC) : 0)) =>
                :BOP_Cost_per_MW,
    )

    dfGen[!, :BOP_OM_Cost_per_MW] =
        round.(dfGen[!, :BOP_Cost_per_MW] .* dfGen[!, :Fixed_OM_Cost_Percentage]; sigdigits = 6)

    ## Drop intermediate columns
    select!(
        dfGen,
        Not([
            :Foundation,
            :Foundation_Cost_per_MW,
            :Foundation_Installation_Cost_per_MW,
            :Mooring_System_Cost_per_MW,
        ]),
    )

    ## Methanol transport unit costs per tonne per km
    Methanol_Sea_Transport_Costs_per_km_per_ton =
        power_settings["Methanol_Sea_Transport_Costs_per_km_per_ton"]

    dfGen = transform(
        dfGen,
        [:R_ID, :Distance, :Electricity_to_Methanol_Rate_MWh_per_tonne] =>
            ByRow(
                (R, D, E2M) -> (
                    R in Offshore_WT ?
                    1.609 * D * Methanol_Sea_Transport_Costs_per_km_per_ton / E2M : 0
                ),
            ) => :Methanol_Transport_Costs_per_MWh,
    )

    power_inputs["dfGen"] = dfGen
    inputs["PowerInputs"] = power_inputs

    return inputs
end
