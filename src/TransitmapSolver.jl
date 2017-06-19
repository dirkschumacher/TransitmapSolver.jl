module TransitmapSolver
    using JuMP
    import MathProgBase
    using DataStructures

    include("types.jl")
    include("transitmap.jl")
    include("mipmodel.jl")
    include("optimze.jl")
    include("parallel-edges.jl")

    export Station
    export Edge
    export GeoCoordinate
    export GeoStation
    export EuclideanCoordinate
    export EuclideanStation
    export EuclideanEdge
    export Line
    export GeoTransitMap
    export InputGraph
    export ProcessedEdge
    export optimize
    export TransitMapLayout
    export angle_deg
end # module
