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
function write_costs_composition(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Writing Sector Costs Composition")

    save_path = settings["SavePath"]

    ## Initialize costs list
    costs_composition = DataFrame(A = String[], B = String[], C = String[], D = Float64[])

    ## Power sector costs composition
    if settings["ModelPower"] == 1
        power_inputs = inputs["PowerInputs"]
        dfGen = power_inputs["dfGen"]

        costs_composition = write_power_costs_composition(costs_composition, settings, inputs, MESS)

        ## Connection line costs composition
        if in("Hub_Longitude", names(dfGen)) &&
           in("Hub_Latitude", names(dfGen)) &&
           (
               haskey(inputs, "Connection_Costs_per_MW_per_km") ||
               haskey(inputs, "Connection_Costs_per_MW") ||
               haskey(inputs, "Connection_Costs_per_km")
           )
            ePObjNetworkConnection =
                value(MESS[:ePObjNetworkConnection]) - settings["eObjHubConnectionExcess"]
        else
            ePObjNetworkConnection = 0.0
        end
        push!(costs_composition, ["Connection Costs", "-", "-", ePObjNetworkConnection])

        ## Substation costs composition
        if inputs["Case"] == "Offshore_Port"
            push!(costs_composition, ["Substation Costs", "-", "-", value(MESS[:ePObjSubstation])])
        end
    end

    ## Hydrogen sector costs composition
    if settings["ModelHydrogen"] == 1
        costs_composition =
            write_hydrogen_costs_composition(costs_composition, settings, inputs, MESS)
    end

    ## Carbon sector costs composition
    if settings["ModelCarbon"] == 1
        costs_composition =
            write_carbon_costs_composition(costs_composition, settings, inputs, MESS)
        if (
            haskey(settings, "Shipping_Carbon_Costs_per_ton_per_km") &&
            settings["Shipping_Carbon_Costs_per_ton_per_km"] > 0
        ) || (
            haskey(settings, "Shipping_Carbon_Costs_per_ton") &&
            settings["Shipping_Carbon_Costs_per_ton"] > 0
        )
            eCObjCarbonShipCosts = value(MESS[:eCObjCarbonShipCosts])
            push!(costs_composition, ["Carbon Shipping", "-", "-", eCObjCarbonShipCosts])
        end
    end

    ## Synfuels sector costs composition
    if settings["ModelSynfuels"] == 1
        costs_composition =
            write_synfuels_costs_composition(costs_composition, settings, inputs, MESS)

        ## Methanol refueling costs composition
        push!(costs_composition, ["Refueling Costs", "-", "-", value(MESS[:eObjRefueling])])
        if haskey(settings, "Shipping_Methanol_Costs_per_ton_per_km") &&
           settings["Shipping_Methanol_Costs_per_ton_per_km"] >= 0
            eSObjMethanolShipCosts = value(MESS[:eSObjMethanolShipCosts])
            push!(costs_composition, ["Methanol Shipping", "-", "-", eSObjMethanolShipCosts])
        end

        ## Onboard carbon capture and Storage costs
        push!(
            costs_composition,
            [
                "Onboard Shipping Carbon Capture & Storage Costs",
                "-",
                "-",
                value(MESS[:eObjShippingCarbonCapSto]),
            ],
        )
    end

    ## Central hub case energy transport costs
    if inputs["Case"] == "Offshore_Hub"
        if haskey(settings, "Refueling_Carbon_Transport_Costs_Slope_per_km_per_tonne") &&
           haskey(settings, "Refueling_Carbon_Transport_Costs_Intercept_per_tonne") &&
           (
               settings["Refueling_Carbon_Transport_Costs_Slope_per_km_per_tonne"] > 0 ||
               settings["Refueling_Carbon_Transport_Costs_Intercept_per_tonne"] > 0
           )
            eObjShippingCarbonTransport = value(MESS[:eObjShippingCarbonTransport])
            push!(
                costs_composition,
                [
                    "Unloaded Carbon Pipeline Transport",
                    "Carbon Transmission",
                    "-",
                    eObjShippingCarbonTransport,
                ],
            )
        end
    end

    if settings["ModelPower"] == 1 &&
       settings["ModelHydrogen"] == 1 &&
       settings["ModelCarbon"] == 1 &&
       settings["ModelSynfuels"] == 1
        eObjCarbonTransport = value(MESS[:eObjCarbonTransport])
        push!(
            costs_composition,
            ["Carbon Transport", "Carbon Transmission", "-", eObjCarbonTransport],
        )
        eObjCarbonShipCosts = value(MESS[:eObjCarbonShipCosts])
        push!(
            costs_composition,
            ["Carbon Shipping", "Carbon Transmission", "-", eObjCarbonShipCosts],
        )
        eObjMethanolTransport = value(MESS[:eObjMethanolTransport])
        push!(
            costs_composition,
            ["Methanol Transport", "Methanol Transmission", "-", eObjMethanolTransport],
        )
    end

    ## Hub costs composition
    push!(
        costs_composition,
        [
            "Hub Costs",
            "-",
            "-",
            value(MESS[:eObjHubAreaInvestment]) + settings["eObjHubVolumeInvestment"],
        ],
    )

    ## Total costs from all energy sectors
    push!(costs_composition, ["Sum", "Sum", "Sum", sum(costs_composition[!, :D])])

    rename!(costs_composition, Symbol.(["Sector", "Sector Costs", "Costs Components", "Case"]))

    CSV.write(joinpath(save_path, "costs_composition.csv"), costs_composition)

    simplified_costs_composition = DataFrame(A = String[], B = Float64[])

    push!(
        simplified_costs_composition,
        [
            "Renewable Investment",
            sum(
                costs_composition[
                    (costs_composition[
                        !,
                        Symbol("Costs Components"),
                    ] .== "Offshore WT Investment") .|| (costs_composition[
                        !,
                        Symbol("Costs Components"),
                    ] .== "Onshore WT Investment") .|| (costs_composition[
                        !,
                        Symbol("Costs Components"),
                    ] .== "Onshore PV Investment"),
                    Symbol("Case"),
                ],
            ),
        ],
    )
    push!(
        simplified_costs_composition,
        [
            "Nuclear Investment",
            sum(
                costs_composition[
                    costs_composition[!, Symbol("Costs Components")] .== "Nuclear Investment",
                    Symbol("Case"),
                ],
            ),
        ],
    )
    push!(
        simplified_costs_composition,
        [
            "Fossil Investment",
            sum(
                costs_composition[
                    costs_composition[
                        !,
                        Symbol("Costs Components"),
                    ] .== "Fossil Generators Investment",
                    Symbol("Case"),
                ],
            ),
        ],
    )
    push!(
        simplified_costs_composition,
        [
            "Electrolysis Investment",
            sum(
                costs_composition[
                    costs_composition[!, Symbol("Costs Components")] .== "Electrolysis Investment",
                    Symbol("Case"),
                ],
            ),
        ],
    )
    push!(
        simplified_costs_composition,
        [
            "DAC Investment",
            sum(
                costs_composition[
                    costs_composition[!, Symbol("Costs Components")] .== "DAC Investment",
                    Symbol("Case"),
                ],
            ),
        ],
    )
    push!(
        simplified_costs_composition,
        [
            "Methanol Investment",
            sum(
                costs_composition[
                    costs_composition[!, Symbol("Costs Components")] .== "Methanol Investment",
                    Symbol("Case"),
                ],
            ),
        ],
    )
    push!(
        simplified_costs_composition,
        [
            "Energy Transport Costs",
            sum(
                costs_composition[
                    occursin.("Transmission", costs_composition[!, Symbol("Sector Costs")]),
                    Symbol("Case"),
                ],
            ),
        ],
    )
    push!(
        simplified_costs_composition,
        [
            "Storage Costs",
            sum(
                costs_composition[
                    occursin.("Storage", costs_composition[!, Symbol("Sector Costs")]),
                    Symbol("Case"),
                ],
            ),
        ],
    )
    push!(
        simplified_costs_composition,
        [
            "Non Served Demand Costs",
            sum(
                costs_composition[
                    costs_composition[!, Symbol("Costs Components")] .== "Non Served Demand Costs",
                    Symbol("Case"),
                ],
            ),
        ],
    )
    push!(
        simplified_costs_composition,
        [
            "Emission Costs",
            sum(
                costs_composition[
                    costs_composition[!, Symbol("Costs Components")] .== "Emission Costs",
                    Symbol("Case"),
                ],
            ),
        ],
    )
    push!(
        simplified_costs_composition,
        [
            "Feedstock Costs",
            sum(
                costs_composition[
                    costs_composition[!, Symbol("Costs Components")] .== "Feedstock Costs",
                    Symbol("Case"),
                ],
            ),
        ],
    )

    if settings["ModelPower"] == 1
        ## Connection line costs composition
        if in("Hub_Longitude", names(dfGen)) &&
           in("Hub_Latitude", names(dfGen)) &&
           (
               haskey(inputs, "Connection_Costs_per_MW_per_km") ||
               haskey(inputs, "Connection_Costs_per_MW") ||
               haskey(inputs, "Connection_Costs_per_km")
           )
            ePObjNetworkConnection =
                value(MESS[:ePObjNetworkConnection]) - settings["eObjHubConnectionExcess"]
        else
            ePObjNetworkConnection = 0.0
        end
        push!(simplified_costs_composition, ["Connection Costs", ePObjNetworkConnection])
        ## Substation cost composition
        if inputs["Case"] == "Offshore_Port"
            push!(simplified_costs_composition, ["Substation Costs", value(MESS[:ePObjSubstation])])
        end
    end

    if settings["ModelCarbon"] == 1
        if (
            haskey(settings, "Shipping_Carbon_Costs_per_ton_per_km") &&
            settings["Shipping_Carbon_Costs_per_ton_per_km"] > 0
        ) || (
            haskey(settings, "Shipping_Carbon_Costs_per_ton") &&
            settings["Shipping_Carbon_Costs_per_ton"] > 0
        )
            eCObjCarbonShipCosts = value(MESS[:eCObjCarbonShipCosts])
            push!(simplified_costs_composition, ["Carbon Shipping", eCObjCarbonShipCosts])
        end
    end

    if settings["ModelSynfuels"] == 1
        ## Methanol refueling costs composition
        push!(simplified_costs_composition, ["Refueling Costs", value(MESS[:eObjRefueling])])
        if haskey(settings, "Shipping_Methanol_Costs_per_ton_per_km") &&
           settings["Shipping_Methanol_Costs_per_ton_per_km"] >= 0
            eSObjMethanolShipCosts = value(MESS[:eSObjMethanolShipCosts])
            push!(simplified_costs_composition, ["Methanol Shipping", eSObjMethanolShipCosts])
        end
        ## Onboard carbon capture and Storage costs
        push!(
            simplified_costs_composition,
            ["Onboard Carbon Capture & Storage Costs", value(MESS[:eObjShippingCarbonCapSto])],
        )
    end
    ## Hub costs composition
    push!(
        simplified_costs_composition,
        ["Hub Costs", value(MESS[:eObjHubAreaInvestment]) + settings["eObjHubVolumeInvestment"]],
    )

    @assert isapprox(sum(simplified_costs_composition[!, :B]), value(MESS[:eObj]); rtol = 0.0001)

    push!(simplified_costs_composition, ["Sum", sum(simplified_costs_composition[!, :B])])

    rename!(simplified_costs_composition, Symbol.(["Costs Components", "Case"]))
    filter!(row -> row.Case != 0, simplified_costs_composition)

    if settings["ModelSynfuels"] == 1
        if haskey(settings, "Shipping_Fuel_Price") &&
           haskey(settings, "Shipping_Fuel_Emission_Factor")
            Shipping_Fuel_Price = settings["Shipping_Fuel_Price"]
            Shipping_Fuel_Emission_Factor = settings["Shipping_Fuel_Emission_Factor"]
        else
            ## Hard coded using inputs from 2023/09/18
            Shipping_Fuel_Price = 1242
            Shipping_Fuel_Emission_Factor = 3.11
        end

        eObjOffset = settings["eObjOffset"]

        transform!(
            simplified_costs_composition,
            [:Case] .=> (x -> x ./ sum(inputs["Shipping_Demand"])) .=> [:Case],
        )
        push!(
            simplified_costs_composition,
            [
                "Methanol Production Cost (\$/t)",
                round(
                    (value(MESS[:eObj]) + eObjOffset) / sum(value.(MESS[:methanol_demand]));
                    sigdigits = 4,
                ),
            ],
        )
        push!(
            simplified_costs_composition,
            [
                "Shipping Fuel Production Cost (\$/t)",
                round(
                    (value(MESS[:eObj]) + eObjOffset) / sum(inputs["Shipping_Demand"]);
                    sigdigits = 4,
                ),
            ],
        )
        push!(
            simplified_costs_composition,
            [
                "Substitution Carbon Price (\$/tonne)",
                round(
                    (
                        (value(MESS[:eObj]) + eObjOffset) / sum(inputs["Shipping_Demand"]) -
                        Shipping_Fuel_Price
                    ) / Shipping_Fuel_Emission_Factor;
                    sigdigits = 4,
                ),
            ],
        )
        push!(
            simplified_costs_composition,
            ["Shipping Fuel Demand (Mt)", round(sum(inputs["Shipping_Demand"] / 1E6); digits = 2)],
        )
        push!(
            simplified_costs_composition,
            ["Shipping Fuel Price (\$/t)", round(Shipping_Fuel_Price; digits = 2)],
        )
        push!(
            simplified_costs_composition,
            [
                "Shipping Fuel Emission Factor (tCO2/t)",
                round(Shipping_Fuel_Emission_Factor; digits = 2),
            ],
        )
    end

    CSV.write(joinpath(save_path, "costs_composition_simplified.csv"), simplified_costs_composition)
end
