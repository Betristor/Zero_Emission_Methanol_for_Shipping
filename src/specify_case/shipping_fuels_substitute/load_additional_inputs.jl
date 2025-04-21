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
function load_additional_inputs(settings::Dict, inputs::Dict)

    print_and_log(settings, "i", "Loading Additional Inputs")

    ## Case differentiation
    if haskey(settings, "Case")
        inputs["Case"] = settings["Case"]
    end

    ## Load shipping substitution fuel transport costs
    if settings["ModelPower"] == 1 &&
       settings["ModelHydrogen"] == 1 &&
       settings["ModelCarbon"] == 1 &&
       settings["ModelSynfuels"] == 1
        inputs = load_methanol_transport_costs(settings, inputs)
    end

    if settings["ModelPower"] == 1
        power_settings = settings["PowerSettings"]
        power_settings["Methanol_Sea_Transport_Costs_per_km_per_ton"] =
            settings["Methanol_Sea_Transport_Costs_per_km_per_ton"]
        power_settings["Methanol_Land_Transport_Costs_per_km_per_ton"] =
            settings["Methanol_Land_Transport_Costs_per_km_per_ton"]
        ## Load hub longitude and latitude if existing, otherwise use zone center coordinates
        inputs = load_power_hub(power_settings, inputs)

        ## Load network lines connecting sub zones
        if inputs["Case"] == "Offshore_Port"
            inputs = load_power_hub_network(power_settings, inputs)
        elseif inputs["Case"] == "Offshore_Hub"
            inputs = load_power_hub_distance(power_settings, inputs)
        end

        ## Load power sector additional inputs
        inputs = load_power_generators_type(power_settings, inputs)

        ## Load power sector offshore/onshore wind turbine and onshore solar panel specified related inputs
        inputs = load_power_offshore_wt_specification(power_settings, inputs)
        inputs = load_power_onshore_vre_specification(power_settings, inputs)

        ## Change power sector inputs to subzone
        inputs = load_power_subzones(power_settings, inputs)
    end

    if settings["ModelHydrogen"] == 1
        hydrogen_settings = settings["HydrogenSettings"]
        ## Change hydrogen sector inputs to subzone
        inputs = load_hydrogen_subzones(hydrogen_settings, inputs)
        ## Load network pipes connecting sub zones
        if inputs["Case"] == "Offshore_Port"
            inputs = load_hydrogen_hub_network(settings, inputs)
        end
    end

    if settings["ModelCarbon"] == 1
        carbon_settings = settings["CarbonSettings"]
        ## Power sector data path
        path = joinpath(settings["RootPath"], settings["CarbonInputs"])

        ## Load carbon sector storage demand
        inputs = load_carbon_storage_demand(carbon_settings, inputs)

        ## Read in shipping routes in carbon sector
        inputs = load_carbon_shipping_routes(path, carbon_settings, inputs)
        carbon_settings["Carbon_Sea_Transport_Costs_per_km_per_ton"] =
            settings["Carbon_Sea_Transport_Costs_per_km_per_ton"]
        carbon_settings["Carbon_Land_Transport_Costs_per_km_per_ton"] =
            settings["Carbon_Land_Transport_Costs_per_km_per_ton"]

        ## Change carbon sector inputs to subzone
        if settings["Case"] != "Offshore_Port"
            inputs = load_carbon_subzones(carbon_settings, inputs)
        end

        inputs = load_carbon_generators(carbon_settings, inputs)
    end

    ## Load shipping demand
    if settings["ModelSynfuels"] == 1
        synfuels_settings = settings["SynfuelsSettings"]
        ## Synfuels sector data path
        path = joinpath(settings["RootPath"], settings["SynfuelsInputs"])

        ## Read in shipping routes in synfuels sector
        if haskey(settings, "Shipping_Methanol_Costs_per_ton_per_km") &&
           settings["Shipping_Methanol_Costs_per_ton_per_km"] >= 0
            inputs = load_synfuels_shipping_routes(path, synfuels_settings, inputs)
        end
        synfuels_settings["Methanol_Sea_Transport_Costs_per_km_per_ton"] =
            settings["Methanol_Sea_Transport_Costs_per_km_per_ton"]
        synfuels_settings["Methanol_Land_Transport_Costs_per_km_per_ton"] =
            settings["Methanol_Land_Transport_Costs_per_km_per_ton"]

        inputs = load_shipping_demand(settings, inputs)

        if settings["Case"] != "Offshore_Port"
            inputs = load_synfuels_subzones(synfuels_settings, inputs)
        end

        inputs = load_synfuels_generators(synfuels_settings, inputs)
    end

    inputs["DZones"] = inputs["Zones"]
    if settings["Case"] != "Offshore_Port"
        inputs["Zones"] = inputs["PowerInputs"]["SubZones"]
        inputs["Z"] = length(inputs["Zones"])
    else
        inputs["Zones"] = union(
            inputs["PowerInputs"]["SubZones"],
            filter(x -> occursin("Port", x), inputs["DZones"]),
        )
        inputs["Z"] = length(inputs["Zones"])

        ## Topology of the network source-sink matrix
        L = inputs["PowerInputs"]["L"]
        Z = inputs["Z"]
        T = inputs["T"]
        Network_map = zeros(L, Z)

        for l in 1:L
            z_start =
                indexin([inputs["PowerInputs"]["dfLine"][!, :Start_SubZone][l]], inputs["Zones"])[1]
            z_end = indexin([inputs["PowerInputs"]["dfLine"][!, :End_Zone][l]], inputs["Zones"])[1]
            Network_map[l, z_start] = 1
            Network_map[l, z_end] = -1
        end

        inputs["PowerInputs"]["Network_map"] = Network_map

        ## Topology of the pipeline network source-sink matrix
        P = inputs["HydrogenInputs"]["P"]
        Pipe_map = zeros(Int64, P, Z)

        for p in 1:P
            z_start =
                indexin([inputs["HydrogenInputs"]["dfPipe"][!, :Start_Zone][p]], inputs["Zones"])[1]
            z_end =
                indexin([inputs["HydrogenInputs"]["dfPipe"][!, :End_Zone][p]], inputs["Zones"])[1]
            Pipe_map[p, z_start] = 1
            Pipe_map[p, z_end] = -1
        end

        Pipe_map = DataFrame(Pipe_map, Symbol.(inputs["Zones"]))

        ## Create pipe number column
        Pipe_map[!, :pipe_no] = 1:size(Pipe_map, 1)

        ## Pivot table
        Pipe_map = stack(Pipe_map, inputs["Zones"])

        ## Remove redundant rows
        Pipe_map = Pipe_map[Pipe_map[!, :value] .!= 0, :]

        ## Rename column
        colnames_pipe_map = ["pipe_no", "Zone", "d"]
        rename!(Pipe_map, Symbol.(colnames_pipe_map))

        inputs["HydrogenInputs"]["Pipe_map"] = Pipe_map

        ## Demand zone to subzone
        inputs["PowerInputs"]["D"] = zeros(Float64, (Z, T))
        inputs["HydrogenInputs"]["D"] = zeros(Float64, (Z, T))
        inputs["CarbonInputs"]["D"] = zeros(Float64, (Z, T))
        inputs["SynfuelsInputs"]["D"] = zeros(Float64, (Z, T))
    end
    return inputs
end
