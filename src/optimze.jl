function optimize(solver::MathProgBase.SolverInterface.AbstractMathProgSolver,
                    transit_map::InputGraph, planarity_constraints::Bool)
    const input_graph = transit_map
    const station_list = stations(input_graph)
    const edge_list = edges(input_graph)
    model = Model(solver = solver)
    const variables = build_model!(model, input_graph, planarity_constraints)
    solve(model)
    const x_val = getvalue(variables.x)
    const y_val = getvalue(variables.y)
    function map_station(i)
        const station = station_list[i]
        const coord = EuclideanCoordinate(x_val[i], y_val[i])
        EuclideanStation(station.id, coord, station.label, station.is_dummy)
    end
    const euclidian_stations = map(map_station, 1:nstations(input_graph))
    function map_edge(i)
        const edge = edge_list[i]
        const idx_from = first(indexin([edge.from], station_list))
        const idx_to = first(indexin([edge.to], station_list))
        Edge(euclidian_stations[idx_from],
             euclidian_stations[idx_to], edge.line)
    end
    const euclidian_edges = map(map_edge, 1:nedges(input_graph))
    TransitMapLayout(euclidian_stations,
        euclidian_edges,
        input_graph.lines)
end
