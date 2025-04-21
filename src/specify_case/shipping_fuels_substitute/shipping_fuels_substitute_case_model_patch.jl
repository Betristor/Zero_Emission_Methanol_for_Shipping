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
function shipping_fuels_substitute_case_model_patch(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Applying Model Patch to Shipping Fuel Substitution Case")

    ## Hub area patch
    MESS = hub_area_patch(settings, inputs, MESS)

    ## Power sector model patch
    if settings["ModelPower"] == 1
        MESS = power_model_patch(settings, inputs, MESS)
    end

    ## Hydrogen sector model patch
    if settings["ModelHydrogen"] == 1
        MESS = hydrogen_model_patch(settings, inputs, MESS)
    end

    ## Carbon sector model patch
    if settings["ModelCarbon"] == 1
        MESS = carbon_model_patch(settings, inputs, MESS)
    end

    ## Synfuels sector model patch
    if settings["ModelSynfuels"] == 1
        MESS = synfuels_model_patch(settings, inputs, MESS)
    end

    ## Methanol transport costs patch
    if settings["ModelPower"] == 1 &&
       settings["ModelHydrogen"] == 1 &&
       settings["ModelCarbon"] == 1 &&
       settings["ModelSynfuels"] == 1
        MESS = methanol_transport_patch(settings, inputs, MESS)
    end

    ## Unregister demand expression, nse constraints and balance
    MESS = remove_registries(settings, inputs, MESS)

    ## Reinitialize demand expression
    if settings["ModelSynfuels"] == 1
        MESS = reinitialize_demand(settings, inputs, MESS)
    end

    ## Reinitialize emission expression
    if settings["ModelSynfuels"] == 1
        MESS = reinitialize_emission(settings, inputs, MESS)
    end

    ## Carbon transport costs patch
    if settings["ModelPower"] == 1 &&
       settings["ModelHydrogen"] == 1 &&
       settings["ModelCarbon"] == 1 &&
       settings["ModelSynfuels"] == 1
        MESS = carbon_transport_patch(settings, inputs, MESS)
    end

    ## Reconstruct the model emission constraints from new inputs
    MESS = rebound_emission(settings, inputs, MESS)

    ## Reconstruct the model balance from new inputs
    MESS = model_balance(settings, inputs, MESS)

    ## Hub investment
    MESS = hub_investment(settings, inputs, MESS)

    ## Reconstruct objective function
    if settings["ModelObjective"] == "patch"
        @objective(MESS, Min, settings["ObjScale"] * MESS[:eObj])
        print_and_log(
            settings,
            "i",
            "Minimizing Objective with Scaling Factor $(settings["ObjScale"])",
        )
    end

    ## Print model to file
    if settings["ModelFile"] != ""
        path = joinpath(settings["SavePath"], settings["ModelFile"])
        write_to_file(MESS, path)
        print_and_log(settings, "i", "MESS Model Instance Resaved to $path")
    end

    return MESS
end
