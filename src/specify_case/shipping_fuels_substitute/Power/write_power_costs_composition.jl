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
function write_power_costs_composition(
    costs_composition::DataFrame,
    settings::Dict,
    inputs::Dict,
    MESS::Model,
)

    print_and_log(settings, "i", "Writing Power Costs Composition")

    CO2Policy = settings["CO2Policy"]

    power_settings = settings["PowerSettings"]

    ## Add PV related costs
    push!(
        costs_composition,
        [
            "Power Sector",
            "Power Generation",
            "Onshore PV Investment",
            round(value(MESS[:eAuxPObjOnshorePV]); digits = 2),
        ],
    )

    ## Add WT related costs
    push!(
        costs_composition,
        [
            "Power Sector",
            "Power Generation",
            "Onshore WT Investment",
            round(value(MESS[:eAuxPObjOnshoreWT]); digits = 2),
        ],
    )

    push!(
        costs_composition,
        [
            "Power Sector",
            "Power Generation",
            "Offshore WT Investment",
            round(value(MESS[:eAuxPObjOffshoreWT]); digits = 2),
        ],
    )

    ## Add feedstock related costs
    push!(
        costs_composition,
        [
            "Feedstock",
            "Power Generation",
            "Feedstock Costs",
            round(value(MESS[:ePObjFeedStock]); digits = 2),
        ],
    )

    ## Add transmission related costs
    if power_settings["ModelTransmission"] == 1
        ePObjNetworkExpansion = value(MESS[:ePObjNetworkExpansion])
    else
        ePObjNetworkExpansion = 0
    end
    push!(
        costs_composition,
        [
            "Power Sector",
            "Power Transmission",
            "Transmission Costs",
            round(ePObjNetworkExpansion; digits = 2),
        ],
    )

    ## Add storage power related costs
    if power_settings["ModelStorage"] == 1
        eAuxPObjStoPower = value(MESS[:eAuxPObjStoPower])
    else
        eAuxPObjStoPower = 0
    end
    push!(
        costs_composition,
        [
            "Power Sector",
            "Power Storage",
            "Storage Power Costs",
            round(eAuxPObjStoPower; digits = 2),
        ],
    )

    ## Add storage energy related costs
    if power_settings["ModelStorage"] == 1
        eAuxPObjStoEnergy = value(MESS[:eAuxPObjStoEnergy])
    else
        eAuxPObjStoEnergy = 0
    end
    push!(
        costs_composition,
        [
            "Power Sector",
            "Power Storage",
            "Storage Energy Costs",
            round(eAuxPObjStoEnergy; digits = 2),
        ],
    )

    ## Add demand related costs
    if power_settings["AllowNse"] == 1
        ePObjVarNse = value(MESS[:ePObjVarNse])
    else
        ePObjVarNse = 0
    end
    push!(
        costs_composition,
        ["Power Sector", "Power Demand", "Non Served Demand Costs", round(ePObjVarNse; digits = 2)],
    )

    ## Add emissions related costs
    if in(4, CO2Policy) || (in(0, CO2Policy) && in(4, power_settings["CO2Policy"]))
        push!(
            costs_composition,
            [
                "Emission",
                "Power Emission",
                "Emission Costs",
                round(value(MESS[:ePObjVarEmission]); digits = 2),
            ],
        )
    end

    return costs_composition
end
