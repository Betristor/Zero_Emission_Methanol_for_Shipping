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
function load_power_hub(power_settings::Dict, inputs::Dict)

    print_and_log(
        power_settings,
        "i",
        "Loading Renewable Energy Hub Position and Calculate Connection Distances",
    )

    ## Get power sector inputs
    power_inputs = inputs["PowerInputs"]
    dfGen = power_inputs["dfGen"]

    ## Get wind turbines' location - longitudes and latitudes
    ## The longitudes and latitudes are given as left top point
    ## and resolution is 0.25 degree
    Lon = dfGen[!, :Longitude] .+ 0.125
    Lat = dfGen[!, :Latitude] .- 0.125

    ## Get corresponding hubs' location - longitudes and latitudes
    if !in("Hub_Longitude", names(dfGen)) || !in("Hub_Latitude", names(dfGen))
        ## Haversine formula for getting center point
        dfGen[!, :X] = cos.(deg2rad.(Lat)) .* cos.(deg2rad.(Lon))
        dfGen[!, :Y] = cos.(deg2rad.(Lat)) .* sin.(deg2rad.(Lon))
        dfGen[!, :Z] = sin.(deg2rad.(Lat))

        # ## Convert back to latitude and longitude
        # CLon = atand(Y, X)
        # CHyp = sqrt(X^2 + Y^2)
        # CLat = atand(Z, CHyp)

        dfGen = transform(
            groupby(dfGen, :SubZone),
            [:X, :Y, :Z] =>
                (
                    (X, Y, Z) -> (
                        Hub_Longitude = atand(mean(Y), mean(X)),
                        Hub_Latitude = atand(mean(Z), sqrt(mean(X)^2 + mean(Y)^2)),
                    )
                ) => AsTable,
        )

        R = 6371 * 0.6214 ## mile
        ## Port coordinates
        RLon = dfGen[!, :Rally_Longitude]
        RLat = dfGen[!, :Rally_Latitude]

        ## Hub coordinates
        HLon = dfGen[!, :Hub_Longitude]
        HLat = dfGen[!, :Hub_Latitude]

        ## Calculate port-hub distances in miles
        dLat = deg2rad.(HLat) .- deg2rad.(RLat)
        dLon = deg2rad.(HLon) .- deg2rad.(RLon)

        a =
            sin.(dLat ./ 2) .^ 2 .+
            cos.(deg2rad.(HLat)) .* cos.(deg2rad.(RLat)) .* sin.(dLon ./ 2) .^ 2
        c = 2 .* asin.(sqrt.(a))
        d = R .* c
        dfGen[!, :Hub_Distance] = d

        ## Calculate line distances in miles
        dLat = deg2rad.(Lat) .- deg2rad.(HLat)
        dLon = deg2rad.(Lon) .- deg2rad.(HLon)

        a =
            sin.(dLat ./ 2) .^ 2 .+
            cos.(deg2rad.(Lat)) .* cos.(deg2rad.(HLat)) .* sin.(dLon ./ 2) .^ 2
        c = 2 .* asin.(sqrt.(a))
        d = R .* c
        dfGen[!, :Line_Distance] = d
    else
        R = 6371 * 0.6214 ## mile
        ## Port coordinates
        RLon = dfGen[!, :Rally_Longitude]
        RLat = dfGen[!, :Rally_Latitude]

        ## Hub coordinates
        HLon = dfGen[!, :Hub_Longitude]
        HLat = dfGen[!, :Hub_Latitude]

        ## Calculate port-hub distances in miles
        dLat = deg2rad.(HLat) .- deg2rad.(RLat)
        dLon = deg2rad.(HLon) .- deg2rad.(RLon)

        a =
            sin.(dLat ./ 2) .^ 2 .+
            cos.(deg2rad.(HLat)) .* cos.(deg2rad.(RLat)) .* sin.(dLon ./ 2) .^ 2
        c = 2 .* asin.(sqrt.(a))
        d = R .* c
        dfGen[!, :Hub_Distance] = d

        ## Calculate line distances in miles
        dLat = deg2rad.(Lat) .- deg2rad.(HLat)
        dLon = deg2rad.(Lon) .- deg2rad.(HLon)

        a =
            sin.(dLat ./ 2) .^ 2 .+
            cos.(deg2rad.(Lat)) .* cos.(deg2rad.(HLat)) .* sin.(dLon ./ 2) .^ 2
        c = 2 .* asin.(sqrt.(a))
        d = R .* c
        dfGen[!, :Line_Distance] = d
    end

    power_inputs["dfGen"] = dfGen
    inputs["PowerInputs"] = power_inputs

    return inputs
end
