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
function shipping_fuels_substitute_case_inputs_patch(settings::Dict, inputs::Dict)

    print_and_log(
        settings,
        "i",
        "Modifying Original Energy Sector Inputs and Load Shipping Sector Demand",
    )

    ## Load modifications
    modification = settings["Modification"]

    ## Case specification
    if haskey(modification, "Case")
        settings["Case"] = modification["Case"]
        delete!(modification, "Case")
    end

    if haskey(modification, "Max_Emission_Mtons")
        inputs["Max_Emission_Mtons"] = modification["Max_Emission_Mtons"]
        delete!(modification, "Max_Emission_Mtons")
    end

    if haskey(modification, "BOP")
        inputs["BOP"] = modification["BOP"]
        delete!(modification, "BOP")
    end

    ## Cell convergence line costs calculation - [mutually exclusive] per MW per km/ per MW/ per km
    if haskey(modification, "Connection_Costs_per_MW_per_km") &&
       modification["Connection_Costs_per_MW_per_km"] > 0
        inputs["Connection_Costs_per_MW_per_km"] = modification["Connection_Costs_per_MW_per_km"]
        delete!(modification, "Connection_Costs_per_MW_per_km")
    end

    if haskey(modification, "Connection_Costs_per_MW") &&
       modification["Connection_Costs_per_MW"] > 0
        inputs["Connection_Costs_per_MW"] = modification["Connection_Costs_per_MW"]
        delete!(modification, "Connection_Costs_per_MW")
    end

    if haskey(modification, "Connection_Costs_per_km") &&
       modification["Connection_Costs_per_km"] > 0
        inputs["Connection_Costs_per_km"] = modification["Connection_Costs_per_km"]
        delete!(modification, "Connection_Costs_per_km")
    end

    if settings["Case"] == "Offshore_Port"
        ## Delivery line when facilities are distributed at both onshore and offshore
        if haskey(modification, "Delivery_Costs_per_km")
            inputs["Delivery_Costs_per_km"] = modification["Delivery_Costs_per_km"]
            delete!(modification, "Delivery_Costs_per_km")
        end

        ## Substation when facilities are distributed at both onshore and offshore
        if haskey(modification, "Substation_Costs_per_MW")
            inputs["Substation_Costs_per_MW"] = modification["Substation_Costs_per_MW"]
            delete!(modification, "Substation_Costs_per_MW")
        end

        ## Substation area when facilities are distributed at both onshore and offshore
        if haskey(modification, "Substation_Area_per_MW")
            inputs["Substation_Area_per_MW"] = modification["Substation_Area_per_MW"]
            delete!(modification, "Substation_Area_per_MW")
        end
    end

    if haskey(modification, "Shipping_Demand_Path")
        settings["Shipping_Demand_Path"] = modification["Shipping_Demand_Path"]
        delete!(modification, "Shipping_Demand_Path")
    end

    if haskey(modification, "Shipping_Demand_Scale")
        settings["Shipping_Demand_Scale"] = modification["Shipping_Demand_Scale"]
        delete!(modification, "Shipping_Demand_Scale")
    end

    if haskey(modification, "Shipping_Fuel_Price")
        settings["Shipping_Fuel_Price"] = modification["Shipping_Fuel_Price"]
        delete!(modification, "Shipping_Fuel_Price")
    end

    if haskey(modification, "Shipping_Fuel_Emission_Factor")
        settings["Shipping_Fuel_Emission_Factor"] = modification["Shipping_Fuel_Emission_Factor"]
        delete!(modification, "Shipping_Fuel_Emission_Factor")
    end

    if haskey(modification, "Shipping_Demand_Methanol_Equivalence_Ratio")
        settings["Shipping_Demand_Methanol_Equivalence_Ratio"] =
            modification["Shipping_Demand_Methanol_Equivalence_Ratio"]
        delete!(modification, "Shipping_Demand_Methanol_Equivalence_Ratio")
    end

    if haskey(modification, "Shipping_Demand_Emission_Capture_Percentage")
        settings["Shipping_Demand_Emission_Capture_Percentage"] =
            modification["Shipping_Demand_Emission_Capture_Percentage"]
        delete!(modification, "Shipping_Demand_Emission_Capture_Percentage")
    end

    if haskey(modification, "Shipping_Demand_Emission_CapSto_Energy_Ratio")
        settings["Shipping_Demand_Emission_CapSto_Energy_Ratio"] =
            modification["Shipping_Demand_Emission_CapSto_Energy_Ratio"]
        delete!(modification, "Shipping_Demand_Emission_CapSto_Energy_Ratio")
    end

    if haskey(modification, "Shipping_Demand_Emission_CapSto_Cost")
        settings["Shipping_Demand_Emission_CapSto_Cost"] =
            modification["Shipping_Demand_Emission_CapSto_Cost"]
        delete!(modification, "Shipping_Demand_Emission_CapSto_Cost")
    end

    if haskey(modification, "Shipping_Methanol_Costs_per_ton_per_km")
        settings["Shipping_Methanol_Costs_per_ton_per_km"] =
            modification["Shipping_Methanol_Costs_per_ton_per_km"]
        delete!(modification, "Shipping_Methanol_Costs_per_ton_per_km")
    end

    if haskey(modification, "Shipping_Carbon_Costs_per_ton_per_km") &&
       haskey(modification, "Shipping_Carbon_Costs_per_ton")
        settings["Shipping_Carbon_Costs_per_ton_per_km"] =
            modification["Shipping_Carbon_Costs_per_ton_per_km"]
        settings["Shipping_Carbon_Costs_per_ton"] = modification["Shipping_Carbon_Costs_per_ton"]
        delete!(modification, "Shipping_Carbon_Costs_per_ton_per_km")
        delete!(modification, "Shipping_Carbon_Costs_per_ton")
    end

    if haskey(modification, "YearlyBalance")
        settings["YearlyBalance"] = modification["YearlyBalance"]
        delete!(modification, "YearlyBalance")
    end

    # if haskey(modification, "Wind_Electricity_Price")
    #     settings["Wind_Electricity_Price"] = modification["Wind_Electricity_Price"]
    #     delete!(modification, "Wind_Electricity_Price")
    # end

    if haskey(modification, "Refueling_Costs")
        settings["Refueling_Costs"] = modification["Refueling_Costs"]
        delete!(modification, "Refueling_Costs")
    end

    ## Offshore hub is posed at sea leading to that carbon is unloaded at port and methanol is refueled at port too
    if settings["Case"] == "Offshore_Hub"
        if haskey(modification, "Refueling_Carbon_Transport_Costs_Slope_per_km_per_tonne") &&
           haskey(modification, "Refueling_Carbon_Transport_Costs_Intercept_per_tonne")
            settings["Refueling_Carbon_Transport_Costs_Slope_per_km_per_tonne"] =
                modification["Refueling_Carbon_Transport_Costs_Slope_per_km_per_tonne"]
            settings["Refueling_Carbon_Transport_Costs_Intercept_per_tonne"] =
                modification["Refueling_Carbon_Transport_Costs_Intercept_per_tonne"]
            delete!(modification, "Refueling_Carbon_Transport_Costs_Slope_per_km_per_tonne")
            delete!(modification, "Refueling_Carbon_Transport_Costs_Intercept_per_tonne")
        end
    end

    if haskey(modification, "Hub_Port_Distance_km")
        settings["Hub_Port_Distance_km"] = modification["Hub_Port_Distance_km"]
        delete!(modification, "Hub_Port_Distance_km")
    end

    if haskey(modification, "Methanol_Sea_Transport_Costs_per_km_per_ton")
        settings["Methanol_Sea_Transport_Costs_per_km_per_ton"] =
            modification["Methanol_Sea_Transport_Costs_per_km_per_ton"]
        delete!(modification, "Methanol_Sea_Transport_Costs_per_km_per_ton")
    end

    if haskey(modification, "Methanol_Land_Transport_Costs_per_km_per_ton")
        settings["Methanol_Land_Transport_Costs_per_km_per_ton"] =
            modification["Methanol_Land_Transport_Costs_per_km_per_ton"]
        delete!(modification, "Methanol_Land_Transport_Costs_per_km_per_ton")
    end

    if haskey(modification, "Carbon_Sea_Transport_Costs_per_km_per_ton")
        settings["Carbon_Sea_Transport_Costs_per_km_per_ton"] =
            modification["Carbon_Sea_Transport_Costs_per_km_per_ton"]
        delete!(modification, "Carbon_Sea_Transport_Costs_per_km_per_ton")
    end

    if haskey(modification, "Carbon_Land_Transport_Costs_per_km_per_ton")
        settings["Carbon_Land_Transport_Costs_per_km_per_ton"] =
            modification["Carbon_Land_Transport_Costs_per_km_per_ton"]
        delete!(modification, "Carbon_Land_Transport_Costs_per_km_per_ton")
    end

    if haskey(modification, "Hub_Area_Costs")
        settings["Hub_Area_Costs"] = modification["Hub_Area_Costs"]
        delete!(modification, "Hub_Area_Costs")
    end

    if haskey(modification, "Hub_Depth_Costs")
        settings["Hub_Depth_Costs"] = modification["Hub_Depth_Costs"]
        delete!(modification, "Hub_Depth_Costs")
    end

    if haskey(modification, "Hub_Volume_Costs")
        settings["Hub_Volume_Costs"] = modification["Hub_Volume_Costs"]
        delete!(modification, "Hub_Volume_Costs")
    end

    if haskey(modification, "Hub_ELE")
        settings["Hub_ELE"] = modification["Hub_ELE"]
        delete!(modification, "Hub_ELE")
    end

    if haskey(modification, "Hub_DAC")
        settings["Hub_DAC"] = modification["Hub_DAC"]
        delete!(modification, "Hub_DAC")
    end

    ## Settings balance location
    settings["CarbonBalance"] = "patch"
    settings["SynfuelsBalance"] = "patch"
    ## Settings objective location
    settings["ModelObjective"] = "patch"

    ## Load additional inputs
    inputs = load_additional_inputs(settings, inputs)

    ## Check whether modifications are all applied
    if isempty(modification)
        print_and_log(settings, "i", "Modification Applied to All")
    end

    return settings, inputs
end
