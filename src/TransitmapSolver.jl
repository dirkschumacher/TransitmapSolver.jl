module TransitmapSolver
using JuMP

include("types.jl")
include("transitmap.jl")
include("mipmodel.jl")
include("optimze.jl")

export Station
export Edge
export GeoCoordinate
export GeoStation
export Line
export GeoTransitMap
export InputGraph
export ProcessedEdge
export optimize

# TODO: write a macro to export enum
#export Direction
#export East
#export West
#export North
#export South
#export SouthEast
#export SouthWest
#export NorthEast
#export NorthWest

end # module
