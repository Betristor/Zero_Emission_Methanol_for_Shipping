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
function run_shipping_case(
    settings_path::AbstractString,
    modification_path::AbstractString,
    modification_number::Integer,
)

    ## Initialize the timer
    to = TimerOutput()

    ## Load settings
    settings = @timeit to "Loading Settings" load_settings(
        modification_path,
        modification_number;
        settings_path = settings_path,
    )

    ## Configure solver
    OPTIMIZER = @timeit to "Configuring Solvers" configure_solver(settings)

    ## Load inputs
    inputs = @timeit to "Loading Inputs" load_inputs(settings)

    ## Apply shipping fuel substitue case inputs patch
    settings, inputs =
        @timeit to "Loading Inputs" shipping_fuels_substitute_case_inputs_patch(settings, inputs)

    ## Generate model
    Model = @timeit to "Generating Model" generate(settings, inputs, OPTIMIZER)

    ## Apply shipping fuel substitue case model patch
    Model = @timeit to "Generating Model" shipping_fuels_substitute_case_model_patch(
        settings,
        inputs,
        Model,
    )

    ## Solve model
    Model = @timeit to "Solving Model" solve(settings, Model)

    ## Apply shipping fuel substitue case write patch
    settings, inputs = @timeit to "Writing Outputs" shipping_fuels_substitute_case_write_patch(
        settings,
        inputs,
        Model,
    )

    ## Write outputs
    outputs = @timeit to "Writing Outputs" write_outputs(settings, inputs, Model)

    showtime(settings, to)
end
