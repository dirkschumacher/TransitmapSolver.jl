using TransitmapSolver
using Base.Test
using JuMP
using GLPKMathProgInterface

tests = [
    "model1",
    "label-placement"]

println("Running tests:")

for t in tests
    test_fn = "$t.jl"
    println(" * $test_fn")
    include(test_fn)
end
