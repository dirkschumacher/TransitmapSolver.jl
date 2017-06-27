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
    export reduce_transitmap
    export classify_direction_sector
    export restore_transitmap
end # module
