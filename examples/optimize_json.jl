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
            res = ProcessedEdge(src, target, line, dir, 1, false)
            if length(filter(x -> x.from == src && x.to == target, result)) == 0
                push!(result, res)
            end
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

arg_len = length(ARGS)
if arg_len != 4
    write(STDERR, "Please supply three arguments: <nodes.ndjson> <edges.ndjson> <3::number of threads> <300::max time for the solver in seconds>")
    exit()
end
nodes_path = ARGS[1]
edges_path = ARGS[2]
no_threads = parse(Int64, ARGS[3])
max_time = parse(Int64, ARGS[4])
lines = readLines(edges_path)
nodes = readNodes(nodes_path)
edges = readEdges(edges_path, nodes, lines)
#edges = filter(x -> !(x.line.id in ["U5"]), edges)
#edges = filter(x -> (x.line.id in [""]), edges)
#println(map(x -> [x.line.id, x.from.id, x.to.id], edges))
nodes = unique(map(x -> x.from, edges) ∪ map(x -> x.to, edges))
lines = unique(map(x -> x.line, edges))


transit_map = InputGraph(nodes, edges, lines)
reduced_transit_map = reduce_transitmap(transit_map)
solver1 = CbcSolver(logLevel = 1, threads = no_threads, seconds = max_time)
result = optimize(solver1, reduced_transit_map, 0)

# restore the original network
result = restore_transitmap(result, transit_map)

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
    source::String
    target::String
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
