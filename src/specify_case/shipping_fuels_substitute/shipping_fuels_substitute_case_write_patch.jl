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
function shipping_fuels_substitute_case_write_patch(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Applying Writing Patch to Shipping Fuel Substitution Case")

    status = termination_status(MESS)

    if settings["Write"] == 1 &&
       status in [MOI.OPTIMAL, MOI.LOCALLY_SOLVED, MOI.ALMOST_LOCALLY_SOLVED]
        if settings["ModelPower"] == 1
            ## Record costs offset into settings
            settings = write_costs_offset(settings, inputs, MESS)

            ## Write energy hub costs
            write_energy_hubs(settings, inputs, MESS)

            ## Write power wind turbine generation lcoe
            write_power_generation_lcoe(settings, inputs, MESS)
        else
            settings["eObjHubVolumeInvestment"] = 0
            settings["eObjOffset"] = 0
        end

        if settings["ModelHydrogen"] == 1
            ## Write hydrogen electrolyser generation lcoe
            write_hydrogen_generation_lcoh(settings, inputs, MESS)
        end

        if settings["ModelCarbon"] == 1
            if (
                haskey(settings, "Shipping_Carbon_Costs_per_ton_per_km") &&
                settings["Shipping_Carbon_Costs_per_ton_per_km"] > 0
            ) || (
                haskey(settings, "Shipping_Carbon_Costs_per_ton") &&
                settings["Shipping_Carbon_Costs_per_ton"] > 0
            )
                ## Write carbon shipping flow & flux
                write_carbon_shipping_flow(settings, inputs, MESS)
                write_carbon_shipping_flux(settings, inputs, MESS)
            end

            ## Write carbon capture lcoc
            write_carbon_capture_lcoc(settings, inputs, MESS)
        end

        if settings["ModelSynfuels"] == 1
            ## Write shipping demand profiles
            write_demand_profiles(settings, inputs, MESS)
            if haskey(settings, "Shipping_Methanol_Costs_per_ton_per_km") &&
               settings["Shipping_Methanol_Costs_per_ton_per_km"] >= 0
                ## Write methanol shipping flow & flux
                write_synfuels_shipping_flow(settings, inputs, MESS)
                write_synfuels_shipping_flux(settings, inputs, MESS)
            end

            ## Write synfuels generation lcof
            write_synfuels_generation_lcof(settings, inputs, MESS)
        end

        ## Write shipping case costs composition
        write_costs_composition(settings, inputs, MESS)

        ## Write shipping case unit fuel substitution price
        if settings["ModelSynfuels"] == 1
            write_shipping_case_prices(settings, inputs, MESS)
        end

        ## Write onboard capture utilization
        write_onboard_capture_carbon(settings, inputs, MESS)

        ## Write shipping case feedstock emission
        write_feedstock_emission(settings, inputs, MESS)
    else
        print_and_log(settings, "w", "Writing is Disabled")
    end

    return settings, inputs
end
