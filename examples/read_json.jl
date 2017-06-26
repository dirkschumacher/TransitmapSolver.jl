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
            angle = angle_deg(Edge(src, target, Line(r["metadata"]["line"])))
            dir = classify_direction_sector(angle)
            println(src.label, "->", target.label, " - ", dir, "; ", angle)
            res = ProcessedEdge(src, target, line, dir, 1, false)
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
#edges = filter(x -> x.line.id in ["U6", "U7", "U8", "U9", "U1", "U2"], edges)
#println(map(x -> [x.line.id, x.from.id, x.to.id], edges))
nodes = unique(map(x -> x.from, edges) ∪ map(x -> x.to, edges))
lines = unique(map(x -> x.line, edges))


transit_map = InputGraph(nodes, edges, lines)
transit_map = reduce_transitmap(transit_map)
solver1 = CbcSolver(logLevel = 0, threads = 3, seconds = 60 * 5)
result = optimize(solver1,
                    transit_map,
                    0)

# convert to json grapg format

type ExportNodeMetaData
    coordinates::EuclideanCoordinate
end
type ExportNode
    id::String
    label::String
    metadata::ExportNodeMetaData
end
type ExportEdgeMetaData
    line::String
end
type ExportEdge
    from::String
    to::String
    metadata::ExportEdgeMetaData
end
type ExportGraph
    nodes::Set{ExportNode}
    edges::Set{ExportEdge}
end

nodes = Set{ExportNode}(map(x -> ExportNode(string(x.id), x.label, ExportNodeMetaData(x.coordinate)), result.stations))
convert_edge = x -> ExportEdge(string(x.from.id), string(x.to.id), ExportEdgeMetaData(x.line.id))
edges = Set{ExportEdge}(map(convert_edge, result.edges))

write("export.json", JSON.json(ExportGraph(nodes, edges)))
#write(STDOUT, JSON.json(ExportGraph(nodes, edges)))
