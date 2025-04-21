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
function load_synfuels_generators(synfuels_settings::Dict, inputs::Dict)

    print_and_log(synfuels_settings, "i", "Loading Synfuels Generators Transport Costs")

    ## Get synfuels sector inputs
    synfuels_inputs = inputs["SynfuelsInputs"]
    dfGen = synfuels_inputs["dfGen"]

    ## Get power sector inputs
    power_inputs = inputs["PowerInputs"]
    dfPGen = power_inputs["dfGen"]

    distances = unique(dfPGen[!, ["Zone", "Distance"]])

    Methanol_Sea_Transport_Costs_per_km_per_ton =
        synfuels_settings["Methanol_Sea_Transport_Costs_per_km_per_ton"]
    Methanol_Land_Transport_Costs_per_km_per_ton =
        synfuels_settings["Methanol_Land_Transport_Costs_per_km_per_ton"]

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
                        occursin("Port", Z) ? Methanol_Land_Transport_Costs_per_km_per_ton :
                        Methanol_Sea_Transport_Costs_per_km_per_ton
                    ) *
                    1.609 *
                    D
                ),
            ) => :Methanol_Transport_Costs_per_tonne,
    )

    synfuels_inputs["dfGen"] = dfGen
    inputs["SynfuelsInputs"] = synfuels_inputs

    return inputs
end
