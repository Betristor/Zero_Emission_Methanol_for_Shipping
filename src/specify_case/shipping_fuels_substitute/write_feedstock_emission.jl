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
function write_feedstock_emission(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Writing Feedstock's Emission Structure")

    save_path = settings["SavePath"]

    ## Basic resolution in time and spatial
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    df = DataFrame(Zone = Zones)

    if settings["ModelFuels"] == 1
        ## Fuel feedstock list
        Fuels_Index = inputs["Fuels_Index"]
        fuels_CO2 = inputs["fuels_CO2"]

        ## Record total feedstock consumption
        fuel_consumption_temp = value.(MESS[:eFuelsConsumption])
        df = hcat(
            df,
            DataFrame(
                Dict(
                    Symbol(Fuels_Index[f] * " (MMBtu)") =>
                        sum(weights[t] * fuel_consumption_temp[f, :, t] for t in 1:T) for
                    f in eachindex(Fuels_Index)
                ),
            ),
        )

        ## Record total feedstock related emission
        df = hcat(
            df,
            DataFrame(
                Dict(
                    Symbol("Feedstock Emission (tonne)") => sum(
                        fuels_CO2[Fuels_Index[f]] *
                        sum(weights[t] * fuel_consumption_temp[f, :, t] for t in 1:T) for
                        f in eachindex(Fuels_Index)
                    ),
                ),
            ),
        )
    end

    ## Record total amount of emission and captured emission
    emission_temp = value.(MESS[:eEmissions])
    captured_temp = value.(MESS[:eCCapture])
    df = hcat(
        df,
        DataFrame(
            Dict(
                Symbol("Apparent Emission (tonne)") =>
                    sum(emission_temp[:, t] - captured_temp[:, t] for t in 1:T),
            ),
        ),
    )

    df = hcat(
        df,
        DataFrame(Dict(Symbol("Captured (tonne)") => sum(captured_temp[:, t] for t in 1:T))),
    )

    if settings["ModelSynfuels"] == 1
        ## Record total amount of emission from traditional demand substitution leakage
        demand_emission_temp =
            value.(MESS[:eSEmissionsByMethanolDemand]) .- value.(MESS[:vAvailableCarbon])
        df = hcat(
            df,
            DataFrame(
                Dict(
                    Symbol("Demand Leakage Emission (tonne)") =>
                        sum(weights[t] * demand_emission_temp[:, t] for t in 1:T),
                ),
            ),
        )

        ## Record total amount of emission from synfuels production leakage
        production_leakage_temp = value.(MESS[:eSEmissionsSynthesisLeakage])
        df = hcat(
            df,
            DataFrame(
                Dict(
                    Symbol("Production Leakage Emission (tonne)") =>
                        sum(weights[t] * production_leakage_temp[:, t] for t in 1:T),
                ),
            ),
        )
    end

    ## Calculate total amount
    push!(df, reduce(vcat, ["Sum", [sum(c) for c in eachcol(df)[2:end]]]))

    ## CSV writing
    CSV.write(joinpath(save_path, "feedstock_emissions.csv"), df)
end
