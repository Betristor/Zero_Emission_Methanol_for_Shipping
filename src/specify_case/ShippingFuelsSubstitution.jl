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

module ShippingFuelsSubstitution

## User functions
export shipping_fuels_substitute_case_inputs_patch
export shipping_fuels_substitute_case_model_patch
export shipping_fuels_substitute_case_write_patch

## External packages
using CSV
using YAML
using Dates

using StatsBase
using Statistics
using DataFrames

using JuMP

using Revise
using Documenter

using Logging
using LoggingExtras
using TimerOutputs

# Auxiliary tools
## Logging
include("../tools/print_and_log.jl")

## Modify data
include("../tools/modify_case/Modify.jl")
using .Modify

## Specific patches
include("../specific_patch/SpecificPatches.jl")
using .SpecificPatches

## Specify Cases
### Shipping fuels substitue case
include("shipping_fuels_substitute/load_additional_inputs.jl")
include("shipping_fuels_substitute/load_methanol_transport_costs.jl")
include("shipping_fuels_substitute/load_shipping_demand.jl")
include("shipping_fuels_substitute/shipping_fuels_substitute_case_inputs_patch.jl")

include("shipping_fuels_substitute/hub_area_patch.jl")
include("shipping_fuels_substitute/carbon_transport_patch.jl")
include("shipping_fuels_substitute/methanol_transport_patch.jl")
include("shipping_fuels_substitute/remove_registries.jl")
include("shipping_fuels_substitute/reinitialize_demand.jl")
include("shipping_fuels_substitute/reinitialize_emission.jl")
include("shipping_fuels_substitute/rebound_emission.jl")
include("shipping_fuels_substitute/model_balance.jl")
include("shipping_fuels_substitute/hub_investment.jl")
include("shipping_fuels_substitute/shipping_fuels_substitute_case_model_patch.jl")

include("shipping_fuels_substitute/write_costs_offset.jl")
include("shipping_fuels_substitute/write_demand_profiles.jl")
include("shipping_fuels_substitute/write_costs_composition.jl")
include("shipping_fuels_substitute/write_shipping_case_prices.jl")
include("shipping_fuels_substitute/write_onboard_capture_carbon.jl")
include("shipping_fuels_substitute/write_feedstock_emission.jl")
include("shipping_fuels_substitute/write_energy_hubs.jl")
include("shipping_fuels_substitute/shipping_fuels_substitute_case_write_patch.jl")

### Power sector patch
include("shipping_fuels_substitute/Power/load_power_hub.jl")
include("shipping_fuels_substitute/Power/load_power_hub_network.jl")
include("shipping_fuels_substitute/Power/load_power_hub_distance.jl")
include("shipping_fuels_substitute/Power/load_power_offshore_wt_specification.jl")
include("shipping_fuels_substitute/Power/load_power_onshore_vre_specification.jl")
include("shipping_fuels_substitute/Power/load_power_generators_type.jl")
include("shipping_fuels_substitute/Power/load_power_subzones.jl")
include("shipping_fuels_substitute/Power/power_model_patch.jl")
include("shipping_fuels_substitute/Power/power_substation_area_patch.jl")
include("shipping_fuels_substitute/Power/power_generation_bop.jl")
include("shipping_fuels_substitute/Power/power_generation_onshore_pv.jl")
include("shipping_fuels_substitute/Power/power_generation_onshore_wt.jl")
include("shipping_fuels_substitute/Power/power_generation_offshore_wt.jl")
include("shipping_fuels_substitute/Power/power_connection.jl")
include("shipping_fuels_substitute/Power/power_substation.jl")
include("shipping_fuels_substitute/Power/write_power_generation_lcoe.jl")
include("shipping_fuels_substitute/Power/write_power_transmission_lcoe.jl")
include("shipping_fuels_substitute/Power/write_power_costs_composition.jl")

### Hydrogen sector patch
include("shipping_fuels_substitute/Hydrogen/load_hydrogen_subzones.jl")
include("shipping_fuels_substitute/Hydrogen/load_hydrogen_hub_network.jl")
include("shipping_fuels_substitute/Hydrogen/hydrogen_model_patch.jl")
include("shipping_fuels_substitute/Hydrogen/hydrogen_area_patch.jl")
include("shipping_fuels_substitute/Hydrogen/hydrogen_generation_electrolyser.jl")
include("shipping_fuels_substitute/Hydrogen/write_hydrogen_generation_lcoh.jl")
include("shipping_fuels_substitute/Hydrogen/write_hydrogen_costs_composition.jl")

### Carbon sector patch
include("shipping_fuels_substitute/Carbon/load_carbon_shipping_routes.jl")
include("shipping_fuels_substitute/Carbon/load_carbon_storage_demand.jl")
include("shipping_fuels_substitute/Carbon/load_carbon_subzones.jl")
include("shipping_fuels_substitute/Carbon/load_carbon_generators.jl")
include("shipping_fuels_substitute/Carbon/carbon_model_patch.jl")
include("shipping_fuels_substitute/Carbon/carbon_area_patch.jl")
include("shipping_fuels_substitute/Carbon/carbon_shipping_patch.jl")
include("shipping_fuels_substitute/Carbon/write_carbon_shipping_flow.jl")
include("shipping_fuels_substitute/Carbon/write_carbon_shipping_flux.jl")
include("shipping_fuels_substitute/Carbon/write_carbon_capture_lcoc.jl")
include("shipping_fuels_substitute/Carbon/write_carbon_costs_composition.jl")

### Synfuels sector patch
include("shipping_fuels_substitute/Synfuels/load_synfuels_shipping_routes.jl")
include("shipping_fuels_substitute/Synfuels/load_synfuels_subzones.jl")
include("shipping_fuels_substitute/Synfuels/load_synfuels_generators.jl")
include("shipping_fuels_substitute/Synfuels/synfuels_model_patch.jl")
include("shipping_fuels_substitute/Synfuels/synfuels_area_patch.jl")
include("shipping_fuels_substitute/Synfuels/synfuels_generation.jl")
include("shipping_fuels_substitute/Synfuels/synfuels_shipping_patch.jl")
include("shipping_fuels_substitute/Synfuels/write_synfuels_shipping_flow.jl")
include("shipping_fuels_substitute/Synfuels/write_synfuels_shipping_flux.jl")
include("shipping_fuels_substitute/Synfuels/write_synfuels_generation_lcof.jl")
include("shipping_fuels_substitute/Synfuels/write_synfuels_costs_composition.jl")

end # module ShippingFuelsSubstitution
