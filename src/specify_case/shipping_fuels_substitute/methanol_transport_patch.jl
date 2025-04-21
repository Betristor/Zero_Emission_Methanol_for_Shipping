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
function methanol_transport_patch(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Methanol Transport Costs Patch")

    T = inputs["T"]

    ## Synfuels generators inputs
    synfuels_inputs = inputs["SynfuelsInputs"]
    dfGen = synfuels_inputs["dfGen"]
    G = synfuels_inputs["G"]

    ### Expressions ###
    ## Methanol transport costs
    @expression(
        MESS,
        eObjMethanolTransportOGT[g in 1:G, t in 1:T],
        dfGen[!, :Methanol_Transport_Costs_per_tonne][g] * MESS[:vSGen][g, t]
    )

    @expression(
        MESS,
        eObjMethanolTransportOG[g in 1:G],
        sum(MESS[:eObjMethanolTransportOGT][g, t] for t in 1:T; init = 0.0)
    )

    @expression(
        MESS,
        eObjMethanolTransport,
        sum(MESS[:eObjMethanolTransportOG][g] for g in 1:G; init = 0.0)
    )

    ## Add term to objective function expression
    add_to_expression!(MESS[:eObj], MESS[:eObjMethanolTransport])

    return MESS
end
