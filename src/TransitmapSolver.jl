module TransitmapSolver
using JuMP
import MathProgBase
using DataStructures

include("types.jl")
include("transitmap.jl")
include("mipmodel.jl")
include("optimze.jl")

export Station
export Edge
export EuclideanCoordinate
export EuclideanStation
export Line
export InputGraph
export ProcessedEdge
export optimize

end # module
