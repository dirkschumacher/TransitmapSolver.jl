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

function inbound_edges(transit_map::TransitMap, station::Station)
    is_connected = x -> x.to == station && !x.is_single_label_edge
    filter(is_connected, edges(transit_map))
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

function angle_deg(edge)
    # as on https://stackoverflow.com/a/9970297/2798441
    # by John Ericksen https://stackoverflow.com/users/654187/john-ericksen
    res = rad2deg(atan2(edge.to.coordinate.y - edge.from.coordinate.y,
            edge.to.coordinate.x - edge.from.coordinate.x))
    if res < 0
        res + 360
    else
        res
    end
end

# sorts all outbound nodes counter-clockwise
function sorted_outbound_edges(graph::TransitMap, node::EuclideanStation)
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

function find_deg2_sequences(transit_map::TransitMap, start_edge)
    paths = Set()
    const line = start_edge.line
    current_edge = start_edge
    current_path = Vector{ProcessedEdge}([current_edge])
    while true
        const out_edges = filter(x -> x.line == line,
                                outbound_edges(transit_map, current_edge.to))
        is_deg2edge = degree(transit_map, current_edge.to) == 2
        if is_deg2edge
            is_deg2edge = length(out_edges) == 1
        end
        if is_deg2edge
            current_edge = first(out_edges)
            push!(current_path, current_edge)
        else
            # path has ended
            if length(current_path) > 2
                push!(paths, current_path)
            end
            const new_paths = map(x -> find_deg2_sequences(transit_map, x), out_edges)
            for np in new_paths
                union!(paths, np)
            end
            break
        end
    end
    paths
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

function reduce_transitmap(transit_map::InputGraph)
    new_transit_map = transit_map
    # for each line we remove degree 2 edges
    for line in transit_map.lines
        const filter_fun = x -> length(inbound_edges(new_transit_map, x.from)) == 0 && x.line == line
        const start_edge = first(filter(filter_fun, edges(new_transit_map)))
        const deg2seqs = find_deg2_sequences(new_transit_map, start_edge)
        for seq in deg2seqs
            const first_edge = first(seq)
            const last_edge = last(seq)
            const from = first_edge.from
            const to = last_edge.to
            const dir = classify_direction_sector(angle_deg(Edge(from, to, line)))
            const min_length = sum(map(x -> x.min_length, seq))
            const new_edge = ProcessedEdge(from, last_edge.to, line, dir, min_length, false)
            new_edges = filter(x -> !(x in seq), edges(new_transit_map))
            push!(new_edges, new_edge)
            const new_nodes = unique(map(x -> x.from, new_edges) ∪ map(x -> x.to, new_edges))
            new_transit_map = InputGraph(new_nodes, new_edges, transit_map.lines)
        end
    end
    new_transit_map
end
