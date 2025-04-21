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
function write_costs_offset(settings::Dict, inputs::Dict, MESS::Model)

    power_inputs = inputs["PowerInputs"]
    dfGen = power_inputs["dfGen"]
    dfHub = unique(dfGen, :SubZone)

    SubZones = power_inputs["SubZones"]

    ## Volumetric Costs offset - no involvement in optimization ##
    slope = 0.75 # slope of the island - hard coded

    ## Total hub area and seperate area for each hub
    eHubArea = value(MESS[:eHubArea]) # total hub area
    if inputs["Case"] == "Offshore_Port"
        if haskey(inputs, "Substation_Area_per_MW")
            eHubPSubstationArea = value(MESS[:eHubPSubstationArea]) # total substation area
        else
            eHubPSubstationArea = 0
        end
    else
        eHubPSubstationArea = 0
    end
    if settings["ModelHydrogen"] == 1
        if haskey(settings, "Hub_ELE") && settings["Hub_ELE"] == 1
            eHubHElectrolyzerArea = value(MESS[:eHubHElectrolyzerArea]) # total electrolyser area
        else
            eHubHElectrolyzerArea = 0
        end
    else
        eHubHElectrolyzerArea = 0
    end
    if settings["ModelCarbon"] == 1
        if haskey(settings, "Hub_DAC") && settings["Hub_DAC"] == 1
            eHubCDirectAirCaptureArea = value(MESS[:eHubCDirectAirCaptureArea]) # total direct air capture area
        else
            eHubCDirectAirCaptureArea = 0
        end
    else
        eHubCDirectAirCaptureArea = 0
    end
    if settings["ModelSynfuels"] == 1
        eHubSMethanolSynthesisArea = value(MESS[:eHubSMethanolSynthesisArea])
    else
        eHubSMethanolSynthesisArea = 0
    end

    # Split hub costs to each hub and components
    # TODO: Assign the correct costs to each offshore hub instead of every hub
    if inputs["Case"] in ["Offshore_Hub", "Onshore_Hub"]
        capacity = value.(MESS[:ePGenCap])
        temp =
            round.(
                [
                    sum(capacity[g] for g in dfGen[dfGen.SubZone .== sz, :R_ID]; init = 0.0) for
                    sz in SubZones
                ];
                digits = 2,
            )
    elseif inputs["Case"] == "Offshore_Port"
        dfLine = power_inputs["dfLine"]
        temp =
            round.(
                [
                    value(MESS[:ePLineCap][dfLine[dfLine.Start_SubZone .== sz, :L_ID][1]]) for
                    sz in SubZones
                ];
                digits = 2,
            )
    end

    ## Area costs calculation using unit costs times total area - active for platform and artificial island
    eSubZoneHubArea = eHubArea .* temp ./ sum(temp)
    eSubZoneHubPSubstationArea = eHubPSubstationArea .* temp ./ sum(temp)
    eSubZoneHubHElectrolyzerArea = eHubHElectrolyzerArea .* temp ./ sum(temp)
    eSubZoneHubCDirectAirCaptureArea = eHubCDirectAirCaptureArea .* temp ./ sum(temp)
    eSubZoneHubSMethanolSynthesisArea = eHubSMethanolSynthesisArea .* temp ./ sum(temp)

    eObjSubZonalHubAreaInvestment = settings["Hub_Area_Costs"] .* eSubZoneHubArea # investment costs of the hub area

    ## Volumetric costs calculation when using artificial island - active when Hub_Volume_Costs > 0
    eSubZoneHubRadius = sqrt.(eSubZoneHubArea ./ pi) # radius of the hub
    eSubZoneHubSeabedRadius = [
        eSubZoneHubRadius[i] > 0 ?
        eSubZoneHubRadius[i] + dfHub[dfHub.SubZone .== SubZones[i], :Hub_Depth][1] / slope : 0
        for i in eachindex(SubZones)
    ] # radius of the seabed
    eSubZoneHubVolume =
        1 / 3 * slope * pi .* (eSubZoneHubSeabedRadius .^ 3 - eSubZoneHubRadius .^ 3) # volume of the hub building materials
    eObjSubZoneHubVolumeInvestment = settings["Hub_Volume_Costs"] .* eSubZoneHubVolume # investment costs of the hub building materials
    eObjHubVolumeInvestment = sum(eObjSubZoneHubVolumeInvestment)

    ## Hub depth costs calculation when using platform - active when Hub_Depth_Costs > 0
    eSubZoneHubDepth = [
        eSubZoneHubArea[i] > 0 ? dfHub[dfHub.SubZone .== SubZones[i], :Hub_Depth][1] : 0 for
        i in eachindex(SubZones)
    ] # depth of the hub
    eObjSubZoneHubDepthInvestment = settings["Hub_Depth_Costs"] .* eSubZoneHubDepth # investment costs of the hub depth
    eObjHubDepthInvestment = sum(eObjSubZoneHubDepthInvestment)

    ## Hub Connection Costs offset - no involvement in optimization ##
    if in("Hub_Longitude", names(dfGen)) && in("Hub_Latitude", names(dfGen))
        if !haskey(inputs, "Connection_Costs_per_MW_per_km") &&
           !haskey(inputs, "Connection_Costs_per_MW") &&
           haskey(inputs, "Connection_Costs_per_km")
            DROPOUT = findall(x -> x == 0.0, round.(value.(MESS[:ePGenCap]); digits = 4))
            eObjHubConnectionExcess =
                sum(value.(MESS[:ePObjNetworkConvergenceCell])[DROPOUT]; init = 0.0)
        else
            eObjHubConnectionExcess = 0
        end
    else
        eObjHubConnectionExcess = 0
    end

    ## Wind electricity curtailment selling savings
    # if inputs["Case"] == "Offshore_Port"
    #     temp =
    #         value.(MESS[:ePAvailableVRESubZonal]).data .- value.(MESS[:ePGenerationVRESubZonal]).data
    #     ePObjCurtailmentSellingOSZ = settings["Wind_Electricity_Price"] .* sum(temp, dims = 2)
    #     ePObjCurtailmentSelling = sum(ePObjCurtailmentSellingOSZ)
    # else
    #     ePObjCurtailmentSelling = 0
    # end

    eObjOffset = eObjHubVolumeInvestment - eObjHubConnectionExcess
    eObj = value(MESS[:eObj])

    print_and_log(
        settings,
        "i",
        "Total Costs Offset from Hub Building and Connection are $(eObjOffset)",
    )
    print_and_log(settings, "i", "Total Costs with Offset Included are $(eObj + eObjOffset)")

    ## Record hub area terms into settings
    settings["eSubZoneHubArea"] = eSubZoneHubArea
    settings["eSubZoneHubPSubstationArea"] = eSubZoneHubPSubstationArea
    settings["eSubZoneHubHElectrolyzerArea"] = eSubZoneHubHElectrolyzerArea
    settings["eSubZoneHubCDirectAirCaptureArea"] = eSubZoneHubCDirectAirCaptureArea
    settings["eSubZoneHubSMethanolSynthesisArea"] = eSubZoneHubSMethanolSynthesisArea

    ## Record costs offset terms into settings
    settings["eObjSubZonalHubAreaInvestment"] = eObjSubZonalHubAreaInvestment
    settings["eObjSubZoneHubVolumeInvestment"] = eObjSubZoneHubVolumeInvestment
    settings["eObjSubZoneHubDepthInvestment"] = eObjSubZoneHubDepthInvestment
    settings["eObjHubVolumeInvestment"] = eObjHubVolumeInvestment
    settings["eObjHubDepthInvestment"] = eObjHubDepthInvestment
    settings["eObjHubConnectionExcess"] = eObjHubConnectionExcess
    settings["eObjOffset"] = eObjOffset

    return settings
end
