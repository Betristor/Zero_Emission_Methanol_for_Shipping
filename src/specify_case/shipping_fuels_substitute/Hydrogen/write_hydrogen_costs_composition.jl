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
function write_hydrogen_costs_composition(
    costs_composition::DataFrame,
    settings::Dict,
    inputs::Dict,
    MESS::Model,
)

    print_and_log(settings, "i", "Writing Hydrogen Costs Composition")

    CO2Policy = settings["CO2Policy"]

    hydrogen_settings = settings["HydrogenSettings"]

    ## Add electrolyser related investment costs
    push!(
        costs_composition,
        [
            "Hydrogen Sector",
            "Hydrogen Generation",
            "Electrolysis Investment",
            round(value(MESS[:eAuxHObjElectrolyser]); digits = 2),
        ],
    )

    ## Add feedstock related costs
    push!(
        costs_composition,
        [
            "Feedstock",
            "Hydrogen Generation",
            "Feedstock Costs",
            round(value(MESS[:eHObjFeedStock]); digits = 2),
        ],
    )

    ## Add transmission related costs
    if hydrogen_settings["SimpleTransport"] == 1
        eHObjTransportCosts = value(MESS[:eHObjTransportCosts])
    else
        eHObjTransportCosts = 0.0
    end
    push!(
        costs_composition,
        [
            "Hydrogen Sector",
            "Hydrogen Transmission",
            "Transport Costs",
            round(eHObjTransportCosts; digits = 2),
        ],
    )
    ## Transmission pipeline investment costs
    if hydrogen_settings["ModelPipelines"] == 1
        eHObjNetworkExpansion = value(MESS[:eHObjNetworkExpansion])
        eHObjFixPipeComp = value(MESS[:eHObjFixPipeComp])
    else
        eHObjNetworkExpansion = 0
        eHObjFixPipeComp = 0
    end
    push!(
        costs_composition,
        [
            "Hydrogen Sector",
            "Hydrogen Transmission",
            "Pipeline Investment",
            round(eHObjNetworkExpansion; digits = 2),
        ],
    )

    ## Transmission pipeline compression costs
    push!(
        costs_composition,
        [
            "Hydrogen Sector",
            "Hydrogen Transmission",
            "Pipeline Compression Investment",
            round(eHObjFixPipeComp; digits = 2),
        ],
    )

    ## Transmission truck related costs
    if hydrogen_settings["ModelTrucks"] == 1
        eHObjFixFomTru = value(MESS[:eHObjFixFomTru])
        eHObjFixFomTruComp = value(MESS[:eHObjFixFomTruComp])
        eHObjVarTru = value(MESS[:eHObjVarTru])
        eHObjVarTruComp = value(MESS[:eHObjVarTruComp])
        if hydrogen_settings["NetworkExpansion"] == 1
            eHObjFixInvTru = value(MESS[:eHObjFixInvTru])
            eHObjFixInvTruComp = value(MESS[:eHObjFixInvTruComp])
        else
            eHObjFixInvTru = 0
            eHObjFixInvTruComp = 0
        end
        ## Transmission truck investment costs
        push!(
            costs_composition,
            [
                "Hydrogen Sector",
                "Hydrogen Transmission",
                "Truck Costs",
                round(eHObjFixInvTru + eHObjFixFomTru + eHObjVarTru; digits = 2),
            ],
        )
        ## Transmission truck compression costs
        push!(
            costs_composition,
            [
                "Hydrogen Sector",
                "Hydrogen Transmission",
                "Truck Compression Costs",
                round(eHObjFixInvTruComp + eHObjFixFomTruComp + eHObjVarTruComp; digits = 2),
            ],
        )
    end

    ## Add storage conditioning related costs
    if hydrogen_settings["ModelStorage"] == 1
        eAuxHObjStoCondition = value(MESS[:eAuxHObjStoCondition])
    else
        eAuxHObjStoCondition = 0
    end
    push!(
        costs_composition,
        [
            "Hydrogen Sector",
            "Hydrogen Storage",
            "Storage Conditioning Costs",
            round(eAuxHObjStoCondition; digits = 2),
        ],
    )

    ## Add storage volume related costs
    if hydrogen_settings["ModelStorage"] == 1
        eAuxHObjStoVolume = value(MESS[:eAuxHObjStoVolume])
    else
        eAuxHObjStoVolume = 0
    end
    push!(
        costs_composition,
        [
            "Hydrogen Sector",
            "Hydrogen Storage",
            "Storage Volume Costs",
            round(eAuxHObjStoVolume; digits = 2),
        ],
    )

    ## Add demand related costs
    if hydrogen_settings["AllowNse"] == 1
        eHObjVarNse = value(MESS[:eHObjVarNse])
    else
        eHObjVarNse = 0
    end
    push!(
        costs_composition,
        [
            "Hydrogen Sector",
            "Hydrogen Demand",
            "Non Served Demand Costs",
            round(eHObjVarNse; digits = 2),
        ],
    )

    ## Add transportation demand facility costs
    if haskey(settings, "Hydrogen_Demand_Cost") && (settings["Case_Identifier"] == "Substitution")
        eObjVarTransportHydrogenDemand = value(MESS[:eObjVarTransportHydrogenDemand])
    else
        eObjVarTransportHydrogenDemand = 0
    end
    push!(
        costs_composition,
        [
            "Hydrogen Sector",
            "Hydrogen Demand",
            "Demand Facility Costs",
            round(eObjVarTransportHydrogenDemand; digits = 2),
        ],
    )

    ## Add emissions related costs
    if in(4, CO2Policy) || (in(0, CO2Policy) && in(4, hydrogen_settings["CO2Policy"]))
        push!(
            costs_composition,
            [
                "Emission",
                "Hydrogen Emission",
                "Emission Costs",
                round(value(MESS[:eHObjVarEmission]); digits = 2),
            ],
        )
    end

    return costs_composition
end
