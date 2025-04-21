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
function power_model_patch(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Applying Patch to Power Sub Model")

    Zones = inputs["Zones"]

    power_settings = settings["PowerSettings"]

    ## BOP of renewable generators
    MESS = power_generation_bop(settings, inputs, MESS)

    ## Onshore solar panel generator patch
    MESS = power_generation_onshore_pv(settings, inputs, MESS)

    ## Onshore wind turbine generator patch
    MESS = power_generation_onshore_wt(settings, inputs, MESS)

    ## Offshore wind turbine generator patch
    MESS = power_generation_offshore_wt(settings, inputs, MESS)

    ## Wind generator connection to the hub
    if haskey(inputs, "Connection_Costs_per_MW_per_km") ||
       haskey(inputs, "Connection_Costs_per_MW") ||
       haskey(inputs, "Connection_Costs_per_km")
        MESS = power_connection(settings, inputs, MESS)
    end

    if inputs["Case"] == "Offshore_Port"
        ## Power sector substation costs
        if haskey(inputs, "Substation_Costs_per_MW")
            MESS = power_substation(settings, inputs, MESS)
        end

        ## Power sector substation area
        if haskey(inputs, "Substation_Area_per_MW")
            MESS = power_substation_area_patch(settings, inputs, MESS)
        end
    end

    ## Storage patch
    if power_settings["ModelStorage"] == 1
        MESS = power_storage_patch(settings, inputs, MESS)
    end

    return MESS
end
