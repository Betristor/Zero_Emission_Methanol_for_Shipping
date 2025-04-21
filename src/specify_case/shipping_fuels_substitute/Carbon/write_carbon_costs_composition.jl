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
function write_carbon_costs_composition(
    costs_composition::DataFrame,
    settings::Dict,
    inputs::Dict,
    MESS::Model,
)

    print_and_log(settings, "i", "Writing Carbon Costs Composition")

    CO2Policy = settings["CO2Policy"]

    carbon_settings = settings["CarbonSettings"]

    ## Add direct air capture related costs
    if carbon_settings["ModelDAC"] == 1
        eCObjFixInvCap = value(MESS[:eCObjFixInvCap])
        eCObjFixFomCap = value(MESS[:eCObjFixFomCap])
        eCObjVarCap = value(MESS[:eCObjVarCap])
    else
        eCObjFixInvCap = 0
        eCObjFixFomCap = 0
        eCObjVarCap = 0
    end
    push!(
        costs_composition,
        [
            "Carbon Sector",
            "Carbon Capture",
            "DAC Investment",
            round(eCObjFixInvCap + eCObjFixFomCap + eCObjVarCap; digits = 2),
        ],
    )

    ## Add feedstock related costs
    push!(
        costs_composition,
        [
            "Feedstock",
            "Carbon Capture",
            "Feedstock Costs",
            round(value(MESS[:eCObjFeedStock]); digits = 2),
        ],
    )

    ## Add transmission related costs
    if carbon_settings["SimpleTransport"] == 1
        eCObjTransportCosts = value(MESS[:eCObjTransportCosts])
    else
        eCObjTransportCosts = 0.0
    end
    push!(
        costs_composition,
        [
            "Carbon Sector",
            "Carbon Transmission",
            "Transport Costs",
            round(eCObjTransportCosts; digits = 2),
        ],
    )
    ## Transmission pipeline investment costs
    if carbon_settings["ModelPipelines"] == 1
        eCObjNetworkExpansion = value(MESS[:eCObjNetworkExpansion])
        eCObjFixPipeComp = value(MESS[:eCObjFixPipeComp])
    else
        eCObjNetworkExpansion = 0
        eCObjFixPipeComp = 0
    end
    push!(
        costs_composition,
        [
            "Carbon Sector",
            "Carbon Transmission",
            "Pipeline Investment",
            round(eCObjNetworkExpansion; digits = 2),
        ],
    )
    ## Transmission pipeline compression costs
    push!(
        costs_composition,
        [
            "Carbon Sector",
            "Carbon Transmission",
            "Pipeline Compression Investment",
            round(eCObjFixPipeComp; digits = 2),
        ],
    )

    ## Transmission truck related costs
    if carbon_settings["ModelTrucks"] == 1
        eCObjFixFomTru = value(MESS[:eCObjFixFomTru])
        eCObjFixFomTruComp = value(MESS[:eCObjFixFomTruComp])
        eCObjVarTru = value(MESS[:eCObjVarTru])
        eCObjVarTruComp = value(MESS[:eCObjVarTruComp])
        if carbon_settings["NetworkExpansion"] == 1
            eCObjFixInvTru = value(MESS[:eCObjFixInvTru])
            eCObjFixInvTruComp = value(MESS[:eCObjFixInvTruComp])
        else
            eCObjFixInvTru = 0
            eCObjFixInvTruComp = 0
        end
        ## Transmission truck investment costs
        push!(
            costs_composition,
            [
                "Carbon Sector",
                "Carbon Transmission",
                "Truck Costs",
                round(eCObjFixInvTru + eCObjFixFomTru + eCObjVarTru; digits = 2),
            ],
        )
        ## Transmission truck compression costs
        push!(
            costs_composition,
            [
                "Carbon Sector",
                "Carbon Transmission",
                "Truck Compression Costs",
                round(eCObjFixInvTruComp + eCObjFixFomTruComp + eCObjVarTruComp; digits = 2),
            ],
        )
    end

    ## Add storage conditioning related costs
    if carbon_settings["ModelStorage"] == 1
        eAuxCObjStoCondition = value(MESS[:eAuxCObjStoCondition])
    else
        eAuxCObjStoCondition = 0
    end
    push!(
        costs_composition,
        [
            "Carbon Sector",
            "Carbon Storage",
            "Storage Conditioning Costs",
            round(eAuxCObjStoCondition; digits = 2),
        ],
    )

    ## Add storage energy related costs
    if carbon_settings["ModelStorage"] == 1
        eAuxCObjStoVolume = value(MESS[:eAuxCObjStoVolume])
    else
        eAuxCObjStoVolume = 0
    end
    push!(
        costs_composition,
        [
            "Carbon Sector",
            "Carbon Storage",
            "Storage Volume Costs",
            round(eAuxCObjStoVolume; digits = 2),
        ],
    )

    ## Add demand related costs
    if carbon_settings["AllowNse"] == 1
        eCObjVarNse = value(MESS[:eCObjVarNse])
    else
        eCObjVarNse = 0
    end
    push!(
        costs_composition,
        [
            "Carbon Sector",
            "Carbon Demand",
            "Non Served Demand Costs",
            round(eCObjVarNse; digits = 2),
        ],
    )

    ## Add emissions related costs
    if in(4, CO2Policy) || (in(0, CO2Policy) && in(4, carbon_settings["CO2Policy"]))
        push!(
            costs_composition,
            [
                "Emission",
                "Carbon Emission",
                "Emission Costs",
                round(value(MESS[:eCObjVarEmission]); digits = 2),
            ],
        )
    end

    return costs_composition
end
