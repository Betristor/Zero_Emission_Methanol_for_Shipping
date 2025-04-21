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
function write_energy_hubs(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Writing Energy Hub Information including Location and Capacity")

    save_path = settings["SavePath"]

    ## Power sector sector dictionary
    power_settings = settings["PowerSettings"]

    ## Power sector inputs dictionary
    power_inputs = inputs["PowerInputs"]
    dfGen = power_inputs["dfGen"]

    if power_settings["SubZone"] == 1
        SubZones = power_inputs["SubZones"]
        ## Get unique generator dataframe for line mapping
        temp = unique(dfGen, Symbol(power_settings["SubZoneKey"]))
    end

    if inputs["Case"] in ["Offshore_Hub", "Onshore_Hub"]
        dfHubs = DataFrame(
            SubZone = SubZones,
            Longitude = temp[in.(temp.SubZone, Ref(SubZones)), :Hub_Longitude],
            Latitude = temp[in.(temp.SubZone, Ref(SubZones)), :Hub_Latitude],
            HubDepth = temp[in.(temp.SubZone, Ref(SubZones)), :Hub_Depth],
            HubTotalArea = round.(settings["eSubZoneHubArea"]; digits = 2),
            HubSubStationArea = round.(settings["eSubZoneHubPSubstationArea"]; digits = 2),
            HubElectrolyzerArea = round.(settings["eSubZoneHubHElectrolyzerArea"]; digits = 2),
            HubDirectAirCaptureArea = round.(
                settings["eSubZoneHubCDirectAirCaptureArea"];
                digits = 2,
            ),
            HubMethanolSynthesisArea = round.(
                settings["eSubZoneHubSMethanolSynthesisArea"];
                digits = 2,
            ),
            HubAreaCosts = round.(settings["eObjSubZonalHubAreaInvestment"]; digits = 2),
            HubVolumeCosts = round.(settings["eObjSubZoneHubVolumeInvestment"]; digits = 2),
            HubDepthCosts = round.(settings["eObjSubZoneHubDepthInvestment"]; digits = 2),
            HubCosts = round.(
                settings["eObjSubZonalHubAreaInvestment"] .+
                settings["eObjSubZoneHubVolumeInvestment"] .+
                settings["eObjSubZoneHubDepthInvestment"];
                digits = 2,
            ),
            GeneratorCapacity = round.(value.(MESS[:ePGenCapOSZ])[SubZones].data; digits = 2),
        )
        dfHubs = vcat(
            dfHubs,
            DataFrame(
                SubZone = "Sum",
                Longitude = mean(dfHubs.Longitude),
                Latitude = mean(dfHubs.Latitude),
                HubDepth = mean(dfHubs.HubDepth),
                HubTotalArea = sum(dfHubs.HubTotalArea),
                HubSubStationArea = sum(dfHubs.HubSubStationArea),
                HubElectrolyzerArea = sum(dfHubs.HubElectrolyzerArea),
                HubDirectAirCaptureArea = sum(dfHubs.HubDirectAirCaptureArea),
                HubMethanolSynthesisArea = sum(dfHubs.HubMethanolSynthesisArea),
                HubAreaCosts = sum(dfHubs.HubAreaCosts),
                HubVolumeCosts = sum(dfHubs.HubVolumeCosts),
                HubDepthCosts = sum(dfHubs.HubDepthCosts),
                HubCosts = sum(dfHubs.HubCosts),
                GeneratorCapacity = sum(dfHubs.GeneratorCapacity),
            ),
        )
    elseif inputs["Case"] == "Offshore_Port"
        dfLine = power_inputs["dfLine"]
        dfLine_Include = filter(
            row -> occursin.("Hub", row.Start_Zone) && occursin.("Port", row.End_Zone),
            dfLine,
        )
        dfHubs = DataFrame(
            SubZone = SubZones,
            Longitude = temp[temp.SubZone .== SubZones, :Hub_Longitude],
            Latitude = temp[temp.SubZone .== SubZones, :Hub_Latitude],
            HubDepth = temp[temp.SubZone .== SubZones, :Hub_Depth],
            HubTotalArea = round.(settings["eSubZoneHubArea"]; digits = 2),
            HubSubStationArea = round.(settings["eSubZoneHubPSubstationArea"]; digits = 2),
            HubElectrolyzerArea = round.(settings["eSubZoneHubHElectrolyzerArea"]; digits = 2),
            HubDirectAirCaptureArea = round.(
                settings["eSubZoneHubCDirectAirCaptureArea"];
                digits = 2,
            ),
            HubMethanolSynthesisArea = round.(
                settings["eSubZoneHubSMethanolSynthesisArea"];
                digits = 2,
            ),
            HubAreaCosts = round.(settings["eObjSubZonalHubAreaInvestment"]; digits = 2),
            HubVolumeCosts = round.(settings["eObjSubZoneHubVolumeInvestment"]; digits = 2),
            HubDepthCosts = round.(settings["eObjSubZoneHubDepthInvestment"]; digits = 2),
            HubCosts = round.(
                settings["eObjSubZonalHubAreaInvestment"] .+
                settings["eObjSubZoneHubVolumeInvestment"];
                digits = 2,
            ),
            LineCapacity = round.(
                value.(MESS[:ePLineCap])[reduce(
                    vcat,
                    [dfLine_Include[dfLine_Include.Start_SubZone .== sz, :L_ID] for sz in SubZones],
                )];
                digits = 2,
            ),
            GeneratorCapacity = round.(value.(MESS[:ePGenCapOSZ])[SubZones].data; digits = 2),
        )
        dfHubs = vcat(
            dfHubs,
            DataFrame(
                SubZone = "Sum",
                Longitude = mean(dfHubs.Longitude),
                Latitude = mean(dfHubs.Latitude),
                HubDepth = mean(dfHubs.HubDepth),
                HubTotalArea = sum(dfHubs.HubTotalArea),
                HubSubStationArea = sum(dfHubs.HubSubStationArea),
                HubElectrolyzerArea = sum(dfHubs.HubElectrolyzerArea),
                HubDirectAirCaptureArea = sum(dfHubs.HubDirectAirCaptureArea),
                HubMethanolSynthesisArea = sum(dfHubs.HubMethanolSynthesisArea),
                HubAreaCosts = sum(dfHubs.HubAreaCosts),
                HubVolumeCosts = sum(dfHubs.HubVolumeCosts),
                HubDepthCosts = sum(dfHubs.HubDepthCosts),
                HubCosts = sum(dfHubs.HubCosts),
                LineCapacity = sum(dfHubs.LineCapacity),
                GeneratorCapacity = sum(dfHubs.GeneratorCapacity),
            ),
        )
    end

    CSV.write(joinpath(save_path, "Hubs.csv"), dfHubs)
end
