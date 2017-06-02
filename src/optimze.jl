function optimize(solver::MathProgBase.SolverInterface.AbstractMathProgSolver,
                    transit_map::InputGraph, planarity_constraints::Bool)
    input_graph = transit_map
    station_list = stations(input_graph)
    edge_list = edges(input_graph)
    model = Model(solver = solver)
    variables = build_model!(model, input_graph, planarity_constraints)
    solve(model)
    x_val = getvalue(variables.x)
    y_val = getvalue(variables.y)
    function map_station(i)
        station = station_list[i]
        coord = EuclideanCoordinate(x_val[i], y_val[i])
        EuclideanStation(station.id, coord, station.label, station.is_dummy)
    end
    euclidian_stations = map(map_station, 1:nstations(input_graph))
    function map_edge(i)
        edge = edge_list[i]
        idx_from = first(indexin([edge.from], station_list))
        idx_to = first(indexin([edge.to], station_list))
        Edge(euclidian_stations[idx_from],
             euclidian_stations[idx_to], edge.line)
    end
    euclidian_edges = map(map_edge, 1:nedges(input_graph))
    TransitMapLayout(euclidian_stations,
        euclidian_edges,
        input_graph.lines)
end
