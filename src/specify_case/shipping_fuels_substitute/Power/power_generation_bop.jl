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
function power_generation_bop(settings::Dict, inputs::Dict, MESS::Model)

    power_inputs = inputs["PowerInputs"]
    dfGen = power_inputs["dfGen"]
    G = power_inputs["G"]

    COMMIT = power_inputs["COMMIT"]

    ### Expressions ###
    ## Costs from balance of plant
    ## Annuitized investment costs for balance of plant
    @expression(
        MESS,
        ePObjFixInvBOPOG[g in 1:G],
        if g in COMMIT
            dfGen[!, :BOP_Cost_per_MW][g] *
            dfGen[!, :AF][g] *
            dfGen[!, :Cap_Size_MW][g] *
            MESS[:ePGenCap][g]
        else
            dfGen[!, :BOP_Cost_per_MW][g] * dfGen[!, :AF][g] * MESS[:ePGenCap][g]
        end
    )
    @expression(MESS, ePObjFixInvBOP, sum(MESS[:ePObjFixInvBOPOG][g] for g in 1:G; init = 0.0))
    ## Add term to objective function expression
    add_to_expression!(MESS[:ePObj], MESS[:ePObjFixInvBOP])
    add_to_expression!(MESS[:eObj], MESS[:ePObjFixInvBOP])

    ## Fixed O&M costs for balance of plant
    @expression(
        MESS,
        ePObjFixFomBOPOG[g in 1:G],
        dfGen[!, :BOP_OM_Cost_per_MW][g] * MESS[:ePGenCap][g]
    )
    @expression(MESS, ePObjFixFomBOP, sum(MESS[:ePObjFixFomBOPOG][g] for g in 1:G; init = 0.0))
    ## Add term to objective function expression
    add_to_expression!(MESS[:ePObj], MESS[:ePObjFixFomBOP])
    add_to_expression!(MESS[:eObj], MESS[:ePObjFixFomBOP])

    return MESS
end
