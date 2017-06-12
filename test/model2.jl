# 1 -> 2
#      |
#      |
#      v
#      3
station1 = EuclideanStation(1, EuclideanCoordinate(1, 4), "test", false)
station2 = EuclideanStation(2, EuclideanCoordinate(2, 4), "test", false)
station3 = EuclideanStation(4, EuclideanCoordinate(2, 2), "test", false)
line1 = Line("S1")
edge = ProcessedEdge(station1, station2, line1, 0, 1, false)
edge2 = ProcessedEdge(station2, station3, line1, 6, 1, false)
transit_map = InputGraph([station1, station2, station3],
    [edge, edge2],
    [line1])


result = optimize(GLPKSolverMIP(msg_lev = 3), transit_map, false)


@test result.stations[1].coordinate.y > result.stations[2].coordinate.y
@test result.stations[1].coordinate.x < result.stations[2].coordinate.x
@test result.stations[2].coordinate.x < result.stations[3].coordinate.x
@test result.stations[2].coordinate.y > result.stations[3].coordinate.y
