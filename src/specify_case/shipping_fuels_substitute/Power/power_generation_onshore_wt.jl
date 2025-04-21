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
function power_generation_onshore_wt(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Applying Patch to Onshore WT Generation")

    power_settings = settings["PowerSettings"]
    IncludeExistingGen = power_settings["IncludeExistingGen"]

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    power_inputs = inputs["PowerInputs"]
    dfGen = power_inputs["dfGen"]
    NEW_GEN_CAP = power_inputs["NEW_GEN_CAP"]
    G = power_inputs["G"]

    Onshore_WT = power_inputs["Onshore_WT"]

    ## Onshore wind turbine capacity
    @expression(
        MESS,
        ePGenCapOnshoreWT,
        sum(MESS[:ePGenCap][g] for g in intersect(Onshore_WT, 1:G); init = 0.0)
    )

    ## Power generation from onshore wt generators - used for writing results, this term is added into balance already
    @expression(
        MESS,
        ePGenerationOnshoreWT[z = 1:Z, t = 1:T],
        sum(
            MESS[:vPGen][g, t] for g in intersect(Onshore_WT, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    ## Costs contribution from onshore PV
    @expression(
        MESS,
        eAuxPObjOnshoreWT,
        sum(MESS[:ePObjFixInvGenOG][g] for g in intersect(Onshore_WT, NEW_GEN_CAP); init = 0.0) +
        sum(MESS[:ePObjFixInvBOPOG][g] for g in intersect(Onshore_WT, 1:G); init = 0.0) +
        sum(MESS[:ePObjFixFomGenOG][g] for g in intersect(Onshore_WT, 1:G); init = 0.0) +
        sum(MESS[:ePObjFixFomBOPOG][g] for g in intersect(Onshore_WT, 1:G); init = 0.0) +
        sum(MESS[:ePObjVarGenOG][g] for g in intersect(Onshore_WT, 1:G); init = 0.0)
    )

    if IncludeExistingGen == 1
        @expression(
            MESS,
            eAuxPObjSunkOnshoreWT,
            sum(MESS[:ePObjFixSunkInvGenOG][g] for g in intersect(Onshore_WT, 1:G); init = 0.0)
        )
        add_to_expression!(MESS[:eAuxPObjOnshoreWT], MESS[:eAuxPObjSunkOnshoreWT])
    end
    ### End Expressions ###

    return MESS
end
