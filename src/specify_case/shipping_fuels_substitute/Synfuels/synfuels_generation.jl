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
function synfuels_generation(settings::Dict, inputs::Dict, MESS::Model)

    synfuels_settings = settings["SynfuelsSettings"]

    Z = inputs["Z"]
    Zones = inputs["Zones"]

    T = inputs["T"]

    synfuels_inputs = inputs["SynfuelsInputs"]
    dfGen = synfuels_inputs["dfGen"]
    NEW_GEN_CAP = synfuels_inputs["NEW_GEN_CAP"]
    G = synfuels_inputs["G"]

    ### Expressions ###
    ## Costs contribution from electrolysers
    @expression(
        MESS,
        eAuxSObjGeneration,
        sum(MESS[:eSObjFixInvGenOG][g] for g in intersect(1:G, NEW_GEN_CAP); init = 0.0) +
        sum(MESS[:eSObjFixFomGenOG][g] for g in 1:G; init = 0.0) +
        sum(MESS[:eSObjVarGenOG][g] for g in 1:G; init = 0.0)
    )

    ## Production leakage idenfication from electrolysers
    @expression(
        MESS,
        eSEmissionsSynthesisLeakage[z in 1:Z, t in 1:T],
        sum(
            MESS[:vSGen][g, t] *
            (dfGen[!, :Carbon_Rate_tonne_per_tonne][g] - synfuels_settings["DemandEmissionFactor"])
            for g in intersect(1:G, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    add_to_expression!.(MESS[:eSEmissions], MESS[:eSEmissionsSynthesisLeakage])
    add_to_expression!.(MESS[:eEmissions], MESS[:eSEmissionsSynthesisLeakage])
    ### End Expressions ###

    return MESS
end
