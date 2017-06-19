using DataFrames
using GLPKMathProgInterface
using Cbc
using MathProgBase
using TransitmapSolver
import JSON

type InputNode
    id::Integer
    latitude::Number
    longitude::Number
end

type InputEdge
    source::InputNode
    target::InputNode
    direction_sector::Int
    min_edge_length::Integer
end

function readNodes(path::String)
    result = Vector{EuclideanStation}()
    open(path, "r") do f
        for ln in eachline(f)
            r = JSON.parse(ln)
            res = EuclideanStation(parse(Int64, r["id"]),
                EuclideanCoordinate(
                    r["metadata"]["latitude"],
                    r["metadata"]["longitude"]
                ),
                r["label"],
                false)
            push!(result, res)
        end
    end
    result
end


function classify_direction_sector(direction_angle::Real)
    if direction_angle > 90 - 22.5 && direction_angle <= 90 + 22.5
        0
    elseif direction_angle > 135 - 22.5 && direction_angle <= 135 + 22.5
        7
    elseif direction_angle > 180 - 22.5 && direction_angle <= 180 + 22.5
        6
    elseif direction_angle > 225 - 22.5 && direction_angle <= 225 + 22.5
        5
    elseif direction_angle > 270 - 22.5 && direction_angle <= 270 + 22.5
        4
    elseif direction_angle > 315 - 22.5 && direction_angle <= 315 + 22.5
        3
    elseif direction_angle > 360 - 22.5 || direction_angle <= 22.5
        2
    elseif direction_angle > 45 - 22.5 && direction_angle <= 45 + 22.5
        1
    else
        error("Should not happen")
    end
end

function readEdges(path::String, nodes, lines)
    result = []
    open(path, "r") do f
        for ln in eachline(f)
            r = JSON.parse(ln)
            src_id = parse(Int64, r["source"])
            target_id = parse(Int64, r["target"])
            src = first(filter(x -> x.id == src_id, nodes))
            target = first(filter(x -> x.id == target_id, nodes))
            line = first(filter(x -> x.id == r["metadata"]["line"], lines))
            dir = classify_direction_sector(angle_deg(Edge(src, target, Line(r["metadata"]["line"]))))
            res = ProcessedEdge(src, target, line, 1, dir, false)
            push!(result, res)
        end
    end
    result
end

function readLines(path::String)
    result = []
    open(path, "r") do f
        for ln in eachline(f)
            r = JSON.parse(ln)
            push!(result, r["metadata"]["line"])
        end
    end
    map(x -> Line(x), unique(result))
end

lines = readLines("edges.ndjson")
nodes = readNodes("nodes.ndjson")
edges = readEdges("edges.ndjson", nodes, lines)
nodes = unique(map(x -> x.from, edges) ∪ map(x -> x.to, edges))
lines = unique(map(x -> x.line, edges))


transit_map = InputGraph(nodes, edges, lines)
solver1 = CbcSolver(logLevel = 0, threads = 3, seconds = 60 * 5) # all heuristics on
result = optimize(solver1,
                    transit_map,
                    0)

write(STDOUT, JSON.json(result))

