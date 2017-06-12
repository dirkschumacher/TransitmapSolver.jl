# 1 -> 2 <- 5
# ^    |    ^
# |    |    |
# |    v    |
# 3 <- 4 -> 6

station1 = EuclideanStation(1, EuclideanCoordinate(1, 4), "test", false)
station2 = EuclideanStation(2, EuclideanCoordinate(2, 4), "test", false)
station3 = EuclideanStation(3, EuclideanCoordinate(1, 1), "test", false)
station4 = EuclideanStation(4, EuclideanCoordinate(2, 2), "test", false)
station5 = EuclideanStation(5, EuclideanCoordinate(3, 4), "test", false)
station6 = EuclideanStation(6, EuclideanCoordinate(3, 1), "test", false)
line1 = Line("S1")
line2 = Line("S2")
edge = ProcessedEdge(station1, station2, line1, 0, 1, false)
edge3 = ProcessedEdge(station2, station4, line1, 6, 1, false)
edge4 = ProcessedEdge(station4, station3, line1, 4, 1, false)
edge5 = ProcessedEdge(station3, station1, line1, 2, 2, false)
edge6 = ProcessedEdge(station5, station2, line2, 4, 1, false)
edge7 = ProcessedEdge(station4, station6, line2, 0, 1, false)
edge8 = ProcessedEdge(station6, station5, line2, 2, 1, false)
transit_map = InputGraph([station1, station2, station3, station4, station5, station6],
    [edge, edge3, edge4, edge5, edge6, edge7, edge8],
    [line1, line2])


result = optimize(GLPKSolverMIP(msg_lev = 3), transit_map, true)

@test length(result.faces) == 2
@test Set([edge, edge3, edge4, edge5]) in result.faces
@test Set([edge6, edge7, edge8, edge3]) in result.faces
