
abstract Coordinate

type Station{T<:Coordinate}
    id::Int
    coordinate::T
    label::String
    is_dummy::Bool
end

type GeoCoordinate <: Coordinate
    latitude::Float64
    longitude::Float64
end

type EuclideanCoordinate <: Coordinate
    x::Integer
    y::Integer
end

typealias GeoStation Station{GeoCoordinate}
typealias EuclideanStation Station{EuclideanCoordinate}

type Line
    id::String
end

abstract GenericEdge{TS<:Station}

type Edge{TS} <: GenericEdge{TS}
    from::TS
    to::TS
    line::Line
end

typealias GeoEdge Edge{GeoStation}

# TODO: How to make sure that station and edges refer to the same station type?
type TransitMap{TS<:Station, TE<:GenericEdge}
    stations::Array{TS}
    edges::Array{TE}
    lines::Array{Line}
end

#@enum Direction North=2 NorthEast=1 East=0 SouthEast=7 South=6 SouthWest=5 West=4 NorthWest=3
typealias Direction Int

type ProcessedEdge{TS} <: GenericEdge{TS}
    from::TS
    to::TS
    line::Line
    direction::Direction
    min_length::Int
    is_single_label_edge::Bool
end

typealias GeoTransitMap TransitMap{GeoStation, GeoEdge}

typealias InputGraph TransitMap{GeoStation, ProcessedEdge{GeoStation}}

# output

type TransitMapLayout
    stations::Array{EuclideanStation}
    edges::Array{Edge{EuclideanStation}}
    lines::Array{Line}
end

type ModelVariables
    x::Any
    y::Any
end
