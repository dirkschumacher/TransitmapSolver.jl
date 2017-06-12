function stations(transit_map::TransitMap)
    transit_map.stations
end

function edges(transit_map::TransitMap)
    transit_map.edges
end

function nstations(transit_map::TransitMap)
    length(stations(transit_map))
end

function nedges(transit_map::TransitMap)
    length(edges(transit_map))
end

function degree(transit_map::TransitMap, station::Station)
    is_connected = x -> x.from == station || x.to == station
    length(filter(is_connected, edges(transit_map)))
end

function outbound_edges(transit_map::TransitMap, station::Station)
    is_connected = x -> x.from == station && !x.is_single_label_edge
    filter(is_connected, edges(transit_map))
end

function out_degree(transit_map::TransitMap, station::Station)
    length(outbound_edges(transit_map, station))
end

# returns a list of incident_edges edges u -> v -> w with the same line
function incident_edges(transit_map::TransitMap)
    edge_list = edges(transit_map)
    incident_edges = Vector{Tuple{GenericEdge, GenericEdge}}()
    for i in 1:nedges(transit_map)
        u = edge_list[i]
        for j in 1:nedges(transit_map)
            if i < j
                v = edge_list[j]
                if u.to == v.from && u.line == v.line
                    push!(incident_edges, (u, v))
                end
            end
        end
    end
    incident_edges
end


function edges_share_face(faces::Set{Set{GenericEdge}}, e1, e2)
    !isempty(filter(x -> e1 in x && e2 in x, faces))
end

# returns a list of faces each edge belongs to
function edge_faces(graph::TransitMap)
    faces = Set{Set{GenericEdge}}()
    for edge in graph.edges
        face_counter_clockwise = find_closest_face(graph, edge, false)
        face_clockwise = find_closest_face(graph, edge, true)
        if length(face_counter_clockwise) <= 2 && length(face_clockwise) <= 2
            continue
        end
        if face_counter_clockwise == face_clockwise
            push!(faces, face_counter_clockwise)
        else
            if length(face_counter_clockwise) > 2
                push!(faces, face_counter_clockwise)
            end
            if length(face_clockwise) > 2
                push!(faces, face_clockwise)
            end
        end
    end
    faces
end

# sorts all outbound nodes counter-clockwise
function sorted_outbound_edges(graph::TransitMap, node::EuclideanStation)
    function angle_deg(edge)
        # as on https://stackoverflow.com/a/9970297/2798441
        # by John Ericksen https://stackoverflow.com/users/654187/john-ericksen
        rad2deg(atan2(edge.from.coordinate.y - edge.to.coordinate.y,
                edge.from.coordinate.x - edge.to.coordinate.x)) % 360
    end
    sort(outbound_edges(graph, node), by = angle_deg)
end

type FaceNode
    element::GenericEdge
    prev::Nullable{FaceNode}
end

# starts traversing the graph clockwise or counterclockwise until
# it finds the edge again
function find_closest_face(graph::TransitMap, edge, counter_clockwise::Bool)
    queue = Queue(FaceNode)
    enqueue!(queue, FaceNode(edge, Nullable{FaceNode}()))
    visited_nodes = Set{GenericEdge}()
    face = Set{GenericEdge}()
    face_found = true
    while !isempty(queue) || !face_found
        current = dequeue!(queue)
        push!(visited_nodes, current.element)
        if current.element.to.id == edge.from.id
            while current != nothing
                push!(face, current.element)
                current = get(current.prev, nothing)
            end
            face_found = true
        else
            neighbors = sorted_outbound_edges(graph, current.element.to)
            if !isempty(neighbors)
                if counter_clockwise
                    el = first(neighbors)
                else
                    el = last(neighbors)
                end
                if !(el in visited_nodes)
                    node = FaceNode(el, Nullable(current))
                    enqueue!(queue, node)
                end
            end
        end
    end
    face
end

function non_incident_edges(transit_map::TransitMap, faces::Set{Set{GenericEdge}})
    non_incident_edges = Vector{Tuple{GenericEdge, GenericEdge}}()
    edge_list = edges(transit_map)
    for i in 1:nedges(transit_map)
        u = edge_list[i]
        for j in 1:nedges(transit_map)
            if i < j
                v = edge_list[j]
                if u.from != v.from && u.from != v.to && u.to != v.from && u.to != v.to &&
                    edges_share_face(faces, u, v)
                    push!(non_incident_edges, (u, v))
                end
            end
        end
    end
    non_incident_edges
end

