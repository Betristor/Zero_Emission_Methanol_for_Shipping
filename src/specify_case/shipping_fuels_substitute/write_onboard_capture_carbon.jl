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

function write_onboard_capture_carbon(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        tsymbols = [Symbol("$t") for t in 1:T]

        save_path = settings["SavePath"]

        ## Write onboard capture profiles into file
        dfs = []

        ## Utilized emission from onboard capture
        df = DataFrame(
            Term = ["Carbon from Onboard Capture By $(Zones[z])" for z in 1:Z],
            Zone = Zones,
            Total = 0,
        )

        df = hcat(df, DataFrame(round.(value.(MESS[:vAvailableCarbon]); sigdigits = 4), :auto))

        push!(dfs, df)

        ## Maximum emission from onboard capture
        df = DataFrame(
            Term = ["Maximum Carbon from Onboard Capture By $(Zones[z])" for z in 1:Z],
            Zone = Zones,
            Total = 0,
        )

        df = hcat(
            df,
            DataFrame(round.(value.(MESS[:eSEmissionsByMethanolDemand]); sigdigits = 4), :auto),
        )

        push!(dfs, df)

        ## Gather all onboard capture emission dataframes into one
        df = reduce(vcat, dfs)

        auxNew_Names = [
            Symbol("Term")
            Symbol("Zone")
            Symbol("Total")
            tsymbols
        ]
        rename!(df, auxNew_Names)

        df[!, :Total] = sum(df[!, c] for c in tsymbols)

        CSV.write(joinpath(save_path, "onboard_capture.csv"), permutedims(df, "Term"))

        ## Annual utilized emission from onboard capture
        utilized = vec(sum(value.(MESS[:vAvailableCarbon]); dims = 2))
        maximum = vec(sum(value.(MESS[:eSEmissionsByMethanolDemand]); dims = 2))

        df = DataFrame(
            Zone = Zones,
            Utilized = utilized,
            Maximum = maximum,
            Utilization = utilized ./ (maximum .+ eps()),
        )
    end
end
