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
function remove_registries(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(
        settings,
        "i",
        "Unregistering Previous Model Balance and Replace Them with New Demand Inputs",
    )

    if settings["ModelSynfuels"] == 1
        unregister(MESS, :eSDemand)
    end

    ## Unregister carbon emission constraints
    if settings["ModelPower"] == 1
        if in(1, settings["PowerSettings"]["CO2Policy"])
            delete(MESS, MESS[:cPEmissionPolicyMass])
            unregister(MESS, :cPEmissionPolicyMass)
        end
    end
    if settings["ModelCarbon"] == 1
        if in(1, settings["CarbonSettings"]["CO2Policy"])
            delete(MESS, MESS[:cCEmissionPolicyMass])
            unregister(MESS, :cCEmissionPolicyMass)
        end
    end
    if settings["ModelSynfuels"] == 1
        if in(1, settings["SynfuelsSettings"]["CO2Policy"])
            delete(MESS, MESS[:cSEmissionPolicyMass])
            unregister(MESS, :cSEmissionPolicyMass)
        end
        if in(2, settings["SynfuelsSettings"]["CO2Policy"])
            delete(MESS, MESS[:cSEmissionPolicyRateLoad])
            unregister(MESS, :cSEmissionPolicyRateLoad)
        end
        unregister(MESS, :eSEmissionsByDemand)
    end

    ## Unregister emission constraint
    if in(1, settings["CO2Policy"])
        delete(MESS, MESS[:cMaxEmission])
        unregister(MESS, :cMaxEmission)
    end

    return MESS
end
