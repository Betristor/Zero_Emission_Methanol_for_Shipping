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
function synfuels_model_patch(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Applying Patch to Synfuels Sub Model")

    synfuels_settings = settings["SynfuelsSettings"]

    ## Synfuels synthesis area patch
    MESS = synfuels_area_patch(settings, inputs, MESS)

    ## Electrolysis generators patch
    MESS = synfuels_generation(settings, inputs, MESS)

    ## Storage patch
    if synfuels_settings["ModelStorage"] == 1
        MESS = synfuels_storage_patch(settings, inputs, MESS)
    end

    if haskey(settings, "Shipping_Methanol_Costs_per_ton_per_km") &&
       settings["Shipping_Methanol_Costs_per_ton_per_km"] >= 0
        MESS = synfuels_shipping_patch(settings, inputs, MESS)
    end

    return MESS
end
