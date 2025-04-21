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
function hydrogen_generation_electrolyser(settings::Dict, inputs::Dict, MESS::Model)

    hydrogen_inputs = inputs["HydrogenInputs"]
    dfGen = hydrogen_inputs["dfGen"]
    NEW_GEN_CAP = hydrogen_inputs["NEW_GEN_CAP"]
    G = hydrogen_inputs["G"]

    ELE = hydrogen_inputs["ELE"]

    ### Expressions ###
    ## Costs contribution from electrolysers
    @expression(
        MESS,
        eAuxHObjElectrolyser,
        sum(MESS[:eHObjFixInvGenOG][g] for g in intersect(ELE, NEW_GEN_CAP); init = 0.0) +
        sum(MESS[:eHObjFixFomGenOG][g] for g in intersect(ELE, 1:G); init = 0.0) +
        sum(MESS[:eHObjVarGenOG][g] for g in intersect(ELE, 1:G); init = 0.0)
    )
    ### End Expressions ###

    return MESS
end
