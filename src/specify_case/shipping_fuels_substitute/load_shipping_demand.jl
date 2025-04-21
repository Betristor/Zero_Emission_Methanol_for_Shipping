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
function load_shipping_demand(settings::Dict, inputs::Dict)

    shipping_demand_scale = settings["Shipping_Demand_Scale"]
    Shipping_Demand_Emission_CapSto_Energy_Ratio =
        settings["Shipping_Demand_Emission_CapSto_Energy_Ratio"]

    ## Shipping demand path for each zone
    shipping_demand_path = joinpath(settings["RootPath"], settings["Shipping_Demand_Path"])
    shipping_demand = DataFrame(CSV.File(shipping_demand_path))

    print_and_log(
        settings,
        "i",
        "Shipping Demand Data Successfully Read from $shipping_demand_path",
    )

    ## Set indices for internal use
    T = inputs["T"]   # Total number of time steps (hours)
    Zones = inputs["Zones"] # List of modeled zones

    ## Load shipping demand emission factor
    shipping_demand_emission_factor = settings["SynfuelsSettings"]["DemandEmissionFactor"]

    ## SDEF short for shipping demand emission factor
    inputs["SDEF"] = shipping_demand_emission_factor

    ## Load shipping sector demand
    inputs["Shipping_Demand"] =
        transpose(Matrix{Float64}(shipping_demand[1:T, ["Load_tonne_$z" for z in Zones]]))

    if any(occursin.("Hub", Zones)) && any(occursin.("Port", Zones))
        print_and_log(
            settings,
            "i",
            "Setting Hub's Demand to Zero and Scale Port's Demand to $(shipping_demand_scale)x",
        )
        inputs["Shipping_Demand"] .*= repeat([0, shipping_demand_scale], Int64(length(Zones) / 2))
    elseif all(occursin.("Hub", Zones)) || all(occursin.("Port", Zones))
        print_and_log(settings, "i", "Scale Hub's Demand to $(shipping_demand_scale)x")
        inputs["Shipping_Demand"] .*= shipping_demand_scale
    end

    print_and_log(
        settings,
        "i",
        "Scale Shipping Demand to $(Shipping_Demand_Emission_CapSto_Energy_Ratio)x due to Emission Capture and Storage Energy Justification",
    )
    inputs["Shipping_Demand"] .*= Shipping_Demand_Emission_CapSto_Energy_Ratio

    total_shipping_demand = dropdims((sum(inputs["Shipping_Demand"], dims = 2)), dims = 2)
    inputs["Total_Shipping_Demand"] = total_shipping_demand
    print_and_log(
        settings,
        "i",
        "Total Shipping Demand to be Replaced is $(round.(total_shipping_demand))",
    )

    return inputs
end
