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
function rebound_emission(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Reconstruct Emission Constraints from New Inputs")

    CO2Policy = settings["CO2Policy"]

    Z = inputs["Z"]
    T = inputs["T"]
    weights = inputs["weights"]

    ## Global emission maximum amount constraint
    if in(1, CO2Policy) && haskey(inputs, "Max_Emission_Mtons")
        @constraint(
            MESS,
            cMaxEmission,
            sum(
                sum(weights[t] * (MESS[:eEmissions][z, t] - MESS[:eDCapture][z, t]) for t in 1:T)
                for z in 1:Z
            ) / 1E6 <= inputs["Max_Emission_Mtons"]
        )
    end

    ## Synfuels emission constraints
    if settings["ModelSynfuels"] == 1
        synfuels_inputs = inputs["SynfuelsInputs"]
        synfuels_settings = settings["SynfuelsSettings"]
        if synfuels_settings["AllowNse"] == 1
            SEG = synfuels_inputs["SEG"]
        end

        if in(2, synfuels_settings["CO2Policy"])
            dfEmi = synfuels_inputs["dfEmi"]
            ## Load + Rate-based: Emissions constraint in terms of rate (tonnes/tonne)
            if synfuels_settings["AllowNse"] == 1
                @constraint(
                    MESS,
                    cSEmissionPolicyRateLoad[z in 1:Z],
                    sum(weights[t] * MESS[:eSEmissions][z, t] for t in 1:T) <=
                    dfEmi[!, :Emission_Max_Tons_tonne][z] * sum(
                        weights[t] * (
                            MESS[:methanol_demand][z, t] +
                            AffExpr(synfuels_inputs["D"][z, t]) +
                            MESS[:eSDemandAddition][z, t] -
                            sum(MESS[:vSDNse][s, z, t] for s in 1:SEG)
                        ) for t in 1:T
                    ) + dfEmi[!, :Emission_Max_Tons_tonne][z] * MESS[:eSStoEneLossOZ][z]
                )
            else
                @constraint(
                    MESS,
                    cSEmissionPolicyRateLoad[z in 1:Z],
                    sum(weights[t] * MESS[:eSEmissions][z, t] for t in 1:T) <=
                    dfEmi[!, :Emission_Max_Tons_tonne][z] * sum(
                        weights[t] * (
                            MESS[:methanol_demand][z, t] +
                            AffExpr(synfuels_inputs["D"][z, t]) +
                            MESS[:eSDemandAddition][z, t]
                        ) for t in 1:T
                    ) + dfEmi[!, :Emission_Max_Tons_tonne][z] * MESS[:eSStoEneLossOZ][z]
                )
            end
        end
    end

    return MESS
end
