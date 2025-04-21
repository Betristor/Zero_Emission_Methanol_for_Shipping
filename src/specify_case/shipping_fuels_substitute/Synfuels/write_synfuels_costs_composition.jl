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
function write_synfuels_costs_composition(
    costs_composition::DataFrame,
    settings::Dict,
    inputs::Dict,
    MESS::Model,
)

    print_and_log(settings, "i", "Writing Synfuels Costs Composition")

    CO2Policy = settings["CO2Policy"]

    synfuels_inputs = inputs["SynfuelsInputs"]
    synfuels_settings = settings["SynfuelsSettings"]

    ## Add synfuels generation related investment costs
    push!(
        costs_composition,
        [
            "Synfuels Sector",
            "Synfuels Generation",
            "Methanol Investment",
            round(value(MESS[:eAuxSObjGeneration]); digits = 2),
        ],
    )

    ## Add feedstock related costs
    push!(
        costs_composition,
        [
            "Feedstock",
            "Synfuels Generation",
            "Feedstock Costs",
            round(value(MESS[:eSObjFeedStock]); digits = 2),
        ],
    )

    ## Add transmission related costs
    if synfuels_settings["SimpleTransport"] == 1
        eSObjTransportCosts = value(MESS[:eSObjTransportCosts])
    else
        eSObjTransportCosts = 0.0
    end
    push!(
        costs_composition,
        [
            "Synfuels Sector",
            "Synfuels Transmission",
            "Transport Costs",
            round(eSObjTransportCosts; digits = 2),
        ],
    )
    ## Transmission pipeline investment costs
    if synfuels_settings["ModelPipelines"] == 1
        eSObjNetworkExpansion = value(MESS[:eSObjNetworkExpansion])
        eSObjFixPipeComp = value(MESS[:eSObjFixPipeComp])
    else
        eSObjNetworkExpansion = 0
        eSObjFixPipeComp = 0
    end
    push!(
        costs_composition,
        [
            "Synfuels Sector",
            "Synfuels Transmission",
            "Pipeline Investment",
            round(eSObjNetworkExpansion; digits = 2),
        ],
    )

    ## Transmission pipeline compression costs
    push!(
        costs_composition,
        [
            "Synfuels Sector",
            "Synfuels Transmission",
            "Pipeline Compression Investment",
            round(eSObjFixPipeComp; digits = 2),
        ],
    )

    ## Transmission truck related costs
    if synfuels_settings["ModelTrucks"] == 1
        eSObjFixFomTru = value(MESS[:eSObjFixFomTru])
        eSObjFixFomTruComp = value(MESS[:eSObjFixFomTruComp])
        eSObjVarTru = value(MESS[:eSObjVarTru])
        eSObjVarTruComp = value(MESS[:eSObjVarTruComp])
        if synfuels_settings["NetworkExpansion"] == 1
            eSObjFixInvTru = value(MESS[:eSObjFixInvTru])
            eSObjFixInvTruComp = value(MESS[:eSObjFixInvTruComp])
        else
            eSObjFixInvTru = 0
            eSObjFixInvTruComp = 0
        end
        ## Transmission truck investment costs
        push!(
            costs_composition,
            [
                "Synfuels Sector",
                "Synfuels Transmission",
                "Truck Costs",
                round(eSObjFixInvTru + eSObjFixFomTru + eSObjVarTru; digits = 2),
            ],
        )
        ## Transmission truck compression costs
        push!(
            costs_composition,
            [
                "Synfuels Sector",
                "Synfuels Transmission",
                "Truck Compression Costs",
                round(eSObjFixInvTruComp + eSObjFixFomTruComp + eSObjVarTruComp; digits = 2),
            ],
        )
    end

    ## Add storage conditioning related costs
    if synfuels_settings["ModelStorage"] == 1
        eAuxSObjStoCondition = value(MESS[:eAuxSObjStoCondition])
    else
        eAuxSObjStoCondition = 0
    end
    push!(
        costs_composition,
        [
            "Synfuels Sector",
            "Synfuels Storage",
            "Storage Conditioning Costs",
            round(eAuxSObjStoCondition; digits = 2),
        ],
    )

    ## Add storage volume related costs
    if synfuels_settings["ModelStorage"] == 1
        eAuxSObjStoVolume = value(MESS[:eAuxSObjStoVolume])
    else
        eAuxSObjStoVolume = 0
    end
    push!(
        costs_composition,
        [
            "Synfuels Sector",
            "Synfuels Storage",
            "Storage Volume Costs",
            round(eAuxSObjStoVolume; digits = 2),
        ],
    )

    ## Add demand related costs
    if synfuels_settings["AllowNse"] == 1
        eSObjVarNse = value(MESS[:eSObjVarNse])
    else
        eSObjVarNse = 0
    end
    push!(
        costs_composition,
        [
            "Synfuels Sector",
            "Synfuels Demand",
            "Non Served Demand Costs",
            round(eSObjVarNse; digits = 2),
        ],
    )

    ## Add emissions related costs
    if in(4, CO2Policy) || (in(0, CO2Policy) && in(4, synfuels_settings["CO2Policy"]))
        push!(
            costs_composition,
            [
                "Emission",
                "Synfuels Emission",
                "Emission Costs",
                round(value(MESS[:eSObjVarEmission]); digits = 2),
            ],
        )
    end

    return costs_composition
end
