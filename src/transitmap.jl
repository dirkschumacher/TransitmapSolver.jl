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

function out_degree(transit_map::TransitMap, station::Station)
    is_connected = x -> x.from == station && !x.is_single_label_edge
    length(filter(is_connected, edges(transit_map)))
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

function non_incident_edges(transit_map::TransitMap)
    non_incident_edges = Vector{Tuple{GenericEdge, GenericEdge}}()
    edge_list = edges(transit_map)
    for i in 1:nedges(transit_map)
        u = edge_list[i]
        for j in 1:nedges(transit_map)
            if i < j
                v = edge_list[j]
                if u.from != v.from && u.from != v.to && u.to != v.from && u.to != v.to
                    push!(non_incident_edges, (u, v))
                end
            end
        end
    end
    non_incident_edges
end

