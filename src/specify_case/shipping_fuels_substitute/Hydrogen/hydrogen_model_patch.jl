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
function hydrogen_model_patch(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Applying Patch to Hydrogen Sub Model")

    hydrogen_settings = settings["HydrogenSettings"]

    ## Hydrogen electrolyser area patch
    if haskey(settings, "Hub_ELE") && settings["Hub_ELE"] == 1
        MESS = hydrogen_area_patch(settings, inputs, MESS)
    end

    ## Electrolyser patch
    MESS = hydrogen_generation_electrolyser(settings, inputs, MESS)

    ## Storage patch
    if hydrogen_settings["ModelStorage"] == 1
        MESS = hydrogen_storage_patch(settings, inputs, MESS)
    end

    return MESS
end
