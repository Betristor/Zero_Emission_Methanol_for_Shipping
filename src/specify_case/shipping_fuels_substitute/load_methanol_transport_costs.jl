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
function load_methanol_transport_costs(settings::Dict, inputs::Dict)

    ## Sectorial generators inputs
    power_inputs = inputs["PowerInputs"]
    hydrogen_inputs = inputs["HydrogenInputs"]
    carbon_inputs = inputs["CarbonInputs"]
    synfuels_inputs = inputs["SynfuelsInputs"]

    ## Generators data
    dfPGen = power_inputs["dfGen"]
    dfHGen = hydrogen_inputs["dfGen"]
    dfCGen = carbon_inputs["dfGen"]
    dfSGen = synfuels_inputs["dfGen"]

    ## Power to methanol - conversion efficiency
    dfPGen = transform(
        dfPGen,
        :Zone =>
            ByRow(
                z ->
                    (
                        inputs["Case"] != "Offshore_Port" ?
                        first(dfSGen[dfSGen.Zone .== z, :Electricity_Rate_MWh_per_tonne]) :
                        0.556
                    ) +
                    (
                        inputs["Case"] != "Offshore_Port" ?
                        first(dfSGen[dfSGen.Zone .== z, :Hydrogen_Rate_tonne_per_tonne]) :
                        0.189
                    ) * first(dfHGen[dfHGen.Zone .== z, :Electricity_Rate_MWh_per_tonne]) +
                    (
                        inputs["Case"] != "Offshore_Port" ?
                        first(dfSGen[dfSGen.Zone .== z, :Carbon_Rate_tonne_per_tonne]) : 1.373
                    ) *
                    (
                        inputs["Case"] != "Offshore_Port" ?
                        first(dfCGen[dfCGen.Zone .== z, :Electricity_Rate_MWh_per_tonne]) :
                        1.63
                    ) *
                    (1 - settings["Shipping_Demand_Emission_Capture_Percentage"]),
            ) => :Electricity_to_Methanol_Rate_MWh_per_tonne,
    )

    power_inputs["dfGen"] = dfPGen

    inputs["PowerInputs"] = power_inputs

    return inputs
end
