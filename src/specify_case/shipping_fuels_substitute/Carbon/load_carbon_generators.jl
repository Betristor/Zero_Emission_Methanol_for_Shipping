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
function load_carbon_generators(carbon_settings::Dict, inputs::Dict)

    print_and_log(carbon_settings, "i", "Loading Carbon Generators Transport Costs")

    ## Get carbon sector inputs
    carbon_inputs = inputs["CarbonInputs"]
    dfGen = carbon_inputs["dfGen"]

    ## Get power sector inputs
    power_inputs = inputs["PowerInputs"]
    dfPGen = power_inputs["dfGen"]

    distances = unique(dfPGen[!, ["Zone", "Distance"]])

    Carbon_Sea_Transport_Costs_per_km_per_ton =
        carbon_settings["Carbon_Sea_Transport_Costs_per_km_per_ton"]
    Carbon_Land_Transport_Costs_per_km_per_ton =
        carbon_settings["Carbon_Land_Transport_Costs_per_km_per_ton"]

    dis = []
    for row in eachrow(dfGen)
        temp =
            (row.Zone in distances.Zone) ?
            first(distances[distances.Zone .== row.Zone, :Distance]) : 0
        push!(dis, temp)
    end
    dfGen[!, :Distance] = dis

    dfGen = transform(
        dfGen,
        [:Zone, :Distance] =>
            ByRow(
                (Z, D) -> (
                    (
                        occursin("Port", Z) ? Carbon_Land_Transport_Costs_per_km_per_ton :
                        Carbon_Sea_Transport_Costs_per_km_per_ton
                    ) *
                    1.609 *
                    D
                ),
            ) => :Carbon_Transport_Costs_per_tonne,
    )

    carbon_inputs["dfGen"] = dfGen
    inputs["CarbonInputs"] = carbon_inputs

    return inputs
end
