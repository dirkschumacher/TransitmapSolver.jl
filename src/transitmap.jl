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

function find_deg2_sequences(transit_map::TransitMap, start_edge::ProcessedEdge, visited_edges::Set{ProcessedEdge})
    paths = Set()
    const line = start_edge.line
    current_edge = start_edge
    current_path = Vector{ProcessedEdge}([current_edge])
    while true
        const out_edges = filter(x -> x.line == line && !(x in visited_edges),
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
            visited_edges = union(visited_edges, Set(current_path))
            const new_paths = map(x -> find_deg2_sequences(transit_map, x, visited_edges), out_edges)
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

# reduce the network so it is easier to solve
# reduces all sequences of deg. 2 nodes to a single, longer edge
function reduce_transitmap(transit_map::InputGraph)
    new_transit_map = transit_map
    # for each line we remove degree 2 edges
    for line in transit_map.lines
        const filter_fun = x -> length(inbound_edges(new_transit_map, x.from)) == 0 && x.line == line
        start_edges = filter(filter_fun, edges(new_transit_map))
        if length(start_edges) == 0
            # we have a cycle
            start_edges = filter(x -> x.line == line, edges(new_transit_map))
            if length(start_edges) == 0
                println(STDERR, "Line ", line.id, " does not have any edges.")
                exit()
            end
        end
        const start_edge = first(start_edges)
        const deg2seqs = find_deg2_sequences(new_transit_map, start_edge, Set{ProcessedEdge}([]))
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

# restores reduced nodes
function restore_transitmap(layout::TransitMapLayout, original_map::InputGraph)
    # find edges that are not part of the original layout
    # sequentially add those edges
    # It was late ... TODO: refactor
    nodes = layout.stations
    const layout_node_ids = Set(map(x -> x.id, nodes))
    node_ids = layout_node_ids # remember what nodes we already added
    edges = layout.edges
    missing_edges = filter(x -> length(filter(y -> y.from.id == x.from.id &&
                                                y.to.id == x.to.id && y.line.id == x.line.id, edges)) == 0, original_map.edges)
    while length(missing_edges) > 0
        # find an edge that starts at a layout node
        const edge = first(filter(x -> x.from.id in layout_node_ids, missing_edges))

        # now find the path to a known edge along the same line
        path = [edge.to]
        current_node = edge.to
        node_found = false
        rm_edges = Set([edge])
        while !node_found
            const next_edges = filter(x -> x.line.id == edge.line.id &&
                                        x.from.id == current_node.id, missing_edges)
            @assert length(next_edges) <= 1
            if length(next_edges) > 0
                current_node = first(next_edges).to
                push!(rm_edges, first(next_edges))
                if !(current_node.id in layout_node_ids)
                    push!(path, current_node)
                else
                    node_found = true
                end
            else
                node_found = true
            end
        end
        filter!(x -> !(x in rm_edges), missing_edges)
        const missing_nodes = filter(x -> !(x in node_ids), path)

        # now add the missing nodes and edges in equi distance
        const reduced_edge = first(filter(x -> x.from.id == edge.from.id && x.line.id == edge.line.id, layout.edges))
        start_coord = reduced_edge.from.coordinate
        end_coord = reduced_edge.to.coordinate
        edge_dist = [end_coord.x - start_coord.x, end_coord.y - start_coord.y] ./ (length(path) + 1)
        i = 1
        last_station = reduced_edge.from
        for new_node in path
            if new_node.id in node_ids
                new_node = first(filter(x -> x.id == new_node.id, nodes))
            else
                new_node.coordinate = EuclideanCoordinate(start_coord.x + edge_dist[1] * i,
                                            start_coord.y + edge_dist[2] * i)
                push!(nodes, new_node)
                push!(node_ids, new_node.id)
            end
            new_edge = Edge(last_station, new_node, edge.line)
            last_station = new_node
            push!(edges, new_edge)
            i = i + 1
        end
        filter!(x -> x != reduced_edge, edges)
        # now add the final edge
        push!(edges, Edge(last_station, reduced_edge.to, edge.line))
    end
    TransitMapLayout(nodes, edges, layout.lines, layout.faces)
end
