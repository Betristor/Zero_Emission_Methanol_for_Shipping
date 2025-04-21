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
function write_power_generation_lcoe(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 2
        path = settings["SavePath"]
        power_settings = settings["PowerSettings"]
        IncludeExistingGen = power_settings["IncludeExistingGen"]
        PReserve = power_settings["PReserve"]

        power_inputs = inputs["PowerInputs"]
        RESOURCES = power_inputs["GenResources"]
        dfGen = power_inputs["dfGen"]

        NEW_GEN_CAP = power_inputs["NEW_GEN_CAP"]
        if PReserve == 1
            GEN_PRSV = power_inputs["GEN_PRSV"]
        end

        ## Generator dataframe
        dfLCOE = DataFrame(Resource = RESOURCES, Zone = string.(dfGen[!, :Zone]))
        dfTotal = DataFrame(Resource = "Sum", Zone = "Sum")

        ## Fix costs - investment costs
        FixInvCosts = zeros(size(RESOURCES))
        for i in NEW_GEN_CAP
            FixInvCosts[i] = value.(MESS[:ePObjFixInvGenOG][i])
        end
        dfLCOE[!, :FixInvCosts] = round.(FixInvCosts; digits = 2)
        dfTotal[!, :FixInvCosts] = [round(sum(FixInvCosts); digits = 2)]

        ## Fix costs - bop investment costs
        FixInvBOPCosts = value.(MESS[:ePObjFixInvBOPOG])
        dfLCOE[!, :FixInvBOPCosts] = round.(FixInvBOPCosts; digits = 2)
        dfTotal[!, :FixInvBOPCosts] = [round(sum(FixInvBOPCosts); digits = 2)]

        ## Fix costs - operation & maintenance costs
        FixFomCosts = value.(MESS[:ePObjFixFomGenOG])
        dfLCOE[!, :FixFomCosts] = round.(FixFomCosts; digits = 2)
        dfTotal[!, :FixFomCosts] = [round(sum(FixFomCosts); digits = 2)]

        ## Fix costs - bop operation & maintenance costs
        FixFomBOPCosts = value.(MESS[:ePObjFixFomBOPOG])
        dfLCOE[!, :FixFomBOPCosts] = round.(FixFomBOPCosts; digits = 2)
        dfTotal[!, :FixFomBOPCosts] = [round(sum(FixFomBOPCosts); digits = 2)]

        ## Fix costs - sunk investment costs
        if IncludeExistingGen == 1
            FixSunkInvCosts = value.(MESS[:ePObjFixSunkInvGenOG])
            dfLCOE[!, :FixSunkInvCosts] = round.(FixSunkInvCosts; digits = 2)
            dfTotal[!, :FixSunkInvCosts] = [round(sum(FixSunkInvCosts); digits = 2)]
        end

        ## Fix costs - convergence line costs
        if in("Hub_Longitude", names(dfGen)) && in("Hub_Latitude", names(dfGen))
            if haskey(inputs, "Connection_Costs_per_MW_per_km") ||
               haskey(inputs, "Connection_Costs_per_MW") ||
               haskey(inputs, "Connection_Costs_per_km")
                FixConvergenceCosts = value.(MESS[:ePObjNetworkConvergenceCell])
                dfLCOE[!, :FixConvergenceCosts] = round.(FixConvergenceCosts; digits = 2)
                dfTotal[!, :FixConvergenceCosts] = [round(sum(FixConvergenceCosts); digits = 2)]
            end
        end

        ## Fix costs - delivery line costs
        if inputs["Case"] == "Offshore_Port"

        end

        ## Variable costs - operation costs
        VarGenCosts = value.(MESS[:ePObjVarGenOG])
        dfLCOE[!, :VarGenCosts] = round.(VarGenCosts; digits = 2)
        dfTotal[!, :VarGenCosts] = [round(sum(VarGenCosts); digits = 2)]

        ## Variable costs - fuel costs
        if settings["ModelFuels"] == 1
            VarFuelCosts = value.(MESS[:ePObjVarFuelOG])
            dfLCOE[!, :VarFuelCosts] = round.(VarFuelCosts; digits = 2)
            dfTotal[!, :VarFuelCosts] = [round(sum(VarFuelCosts); digits = 2)]
        end

        ## Variable costs - primary reserve costs
        if PReserve == 1
            VarGenPRSVCosts = zeros(size(RESOURCES))
            for i in GEN_PRSV
                VarGenPRSVCosts[i] = value.(MESS[:ePObjVarReserveGenOG][i])
            end
            dfLCOE[!, :VarGenPRSVCosts] = round.(VarGenPRSVCosts; digits = 2)
            dfTotal[!, :VarGenPRSVCosts] = [round(sum(VarGenPRSVCosts); digits = 2)]
        end

        ## Total costs of each generator = FixInvCosts + FixFomCosts + FixSunkInvCosts (if) + VarGenCosts
        ## + VarFuelCosts (if) + VarPRSVCosts (if)
        dfLCOE = transform(dfLCOE, Cols(x -> contains(x, "Costs")) => (+) => :Costs)
        dfTotal[!, :Costs] = [round(sum(dfLCOE[!, :Costs]); digits = 2)]

        ## CAPEX and BOP
        dfLCOE[!, :CAPEX] = round.(dfGen[!, :Inv_Cost_per_MW]; digits = 2)
        dfTotal[!, :CAPEX] = [round(mean(dfLCOE[!, :CAPEX]); digits = 2)]

        dfLCOE[!, :BOP] = round.(dfGen[!, :BOP_Cost_per_MW]; digits = 2)
        dfTotal[!, :BOP] = [round(mean(dfLCOE[!, :BOP]); digits = 2)]

        ## Capacity factor
        dfLCOE[!, :Annual_CF] = round.(dfGen[!, :Annual_CF]; digits = 2)
        dfTotal[!, :Annual_CF] = [round(mean(dfLCOE[!, :Annual_CF]); digits = 2)]

        dfLCOE[!, :CapacityFactor] =
            round.(vec(mean(value.(MESS[:vPGen]); dims = 2) ./ value.(MESS[:ePGenCap])); digits = 2)
        dfTotal[!, :CapacityFactor] = [round(mean(dfLCOE[!, :CapacityFactor]); digits = 2)]

        ## Capacity
        dfLCOE[!, :Capacity] = round.(value.(MESS[:ePGenCap]); digits = 2)
        dfTotal[!, :Capacity] = [round(sum(dfLCOE[!, :Capacity]); digits = 2)]

        ## Total generation
        dfLCOE[!, :Generation] = round.(vec(sum(value.(MESS[:vPGen]); dims = 2)); digits = 2)
        dfTotal[!, :Generation] = [round(sum(dfLCOE[!, :Generation]); digits = 2)]

        ## LCOE calulation
        dfLCOE = transform(
            dfLCOE,
            [:Costs, :Generation] =>
                ByRow((C, G) -> G > 0 ? round(C / G; digits = 2) : 0.0) =>
                    Symbol("LCOE (\$/MWh)"),
        )
        dfTotal[!, Symbol("LCOE (\$/MWh)")] = [
            round(
                mean(
                    dfLCOE[dfLCOE[!, Symbol("LCOE (\$/MWh)")] .> 0, Symbol("LCOE (\$/MWh)")],
                    Weights(dfLCOE[dfLCOE[!, Symbol("LCOE (\$/MWh)")] .> 0, :Generation]),
                );
                digits = 2,
            ),
        ]

        ## Database writing
        if haskey(settings, "DB")
            dfGenerator = DataFrame(DBInterface.execute(settings["DB"], "SELECT * FROM PGenerator"))
            dfGenerator = innerjoin(dfGenerator, dfLCOE, on = [:Resource, :ResourceType, :Zone])
            SQLite.drop!(settings["DB"], "PGenerator")
            SQLite.load!(dfGenerator, settings["DB"], "PGenerator")
        end

        dfLCOE = vcat(dfLCOE, dfTotal)

        CSV.write(joinpath(path, "LCOE_generation.csv"), dfLCOE)
    end
end
