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
function write_shipping_case_prices(settings::Dict, inputs::Dict, MESS::Model)

    save_path = settings["SavePath"]

    eObjOffset = settings["eObjOffset"]

    if haskey(settings, "Shipping_Fuel_Price") && haskey(settings, "Shipping_Fuel_Emission_Factor")
        Shipping_Fuel_Price = settings["Shipping_Fuel_Price"]
        Shipping_Fuel_Emission_Factor = settings["Shipping_Fuel_Emission_Factor"]
    else
        ## Hard coded using inputs from 2023/09/18
        Shipping_Fuel_Price = 1242
        Shipping_Fuel_Emission_Factor = 3.11
    end
    prices = DataFrame(
        Dict(
            "MethanolPrice" => round(
                (value(MESS[:eObj]) + eObjOffset) / sum(value.(MESS[:methanol_demand]));
                sigdigits = 4,
            ),
            "FuelPrice" => round(
                (value(MESS[:eObj]) + eObjOffset) / sum(inputs["Shipping_Demand"]);
                sigdigits = 4,
            ),
            "DemandPrice" => round(
                (value(MESS[:eObj]) + eObjOffset) / sum(inputs["Shipping_Demand"]);
                sigdigits = 4,
            ),
            "CarbonPrice" => round(
                (
                    (value(MESS[:eObj]) + eObjOffset) / sum(inputs["Shipping_Demand"]) -
                    Shipping_Fuel_Price
                ) / Shipping_Fuel_Emission_Factor;
                sigdigits = 4,
            ),
        ),
    )

    print_and_log(settings, "i", "Unit Green Methanol Price is $(prices[!, "MethanolPrice"])")
    print_and_log(settings, "i", "Unit Shipping Fuel Price is $(prices[!, "FuelPrice"])")
    print_and_log(settings, "i", "Unit Shipping Demand Price is $(prices[!, "DemandPrice"])")
    print_and_log(settings, "i", "Unit Carbon Price is $(prices[!, "CarbonPrice"])")

    CSV.write(joinpath(save_path, "substitution_prices.csv"), prices)
end
