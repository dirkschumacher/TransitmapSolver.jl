coord1 = EuclideanCoordinate(1, 2)
coord2 = EuclideanCoordinate(1, 3)
station1 = EuclideanStation(1, coord1, "test", false)
station2 = EuclideanStation(2, coord2, "test", false)
station3 = EuclideanStation(3, coord2, "test", false)
station4 = EuclideanStation(4, coord2, "test", false)
station5 = EuclideanStation(5, coord2, "test", false)
station6 = EuclideanStation(6, coord2, "test", false)
station7 = EuclideanStation(7, coord2, "test", false)
station8 = EuclideanStation(8, coord2, "test", false)
station9 = EuclideanStation(9, coord2, "test", false)
line1 = Line("S1")
line2 = Line("S2")
line3 = Line("S3")
line4 = Line("S4")
edge = ProcessedEdge(station1, station2, line1, 0, 1, false)
edge2 = ProcessedEdge(station2, station3, line1, 0, 1, false)
edge3 = ProcessedEdge(station2, station4, line2, 2, 1, false)
edge4 = ProcessedEdge(station5, station2, line2, 2, 1, false)
edge5 = ProcessedEdge(station6, station2, line3, 1, 1, false)
edge6 = ProcessedEdge(station2, station7, line3, 1, 1, false)
edge7 = ProcessedEdge(station8, station2, line4, 3, 1, false)
edge8 = ProcessedEdge(station2, station9, line4, 3, 1, false)
transit_map = InputGraph([station1, station2, station3, station4, station5,
    station6, station7, station8, station9],
    [edge, edge2, edge3, edge4, edge5, edge6, edge7, edge8],
    [line1, line2, line3, line4])

# 9     4    7
#   x   ^   x
#     x | x
# 1 ->  2 -> 3
#     x ^ x
#   x   |   x
# 6     5    8

result = optimize(GLPKSolverMIP(msg_lev = 3), transit_map, false)

@test result.stations[1].coordinate.y ≈ result.stations[2].coordinate.y
@test result.stations[2].coordinate.y ≈ result.stations[3].coordinate.y
@test result.stations[2].coordinate.x ≈ result.stations[4].coordinate.x
@test result.stations[2].coordinate.x ≈ result.stations[5].coordinate.x
@test result.stations[4].coordinate.y > result.stations[5].coordinate.y

@test result.stations[6].coordinate.x ≈ result.stations[9].coordinate.x
@test result.stations[6].coordinate.x ≈ result.stations[1].coordinate.x
@test result.stations[7].coordinate.x ≈ result.stations[8].coordinate.x
@test result.stations[7].coordinate.x ≈ result.stations[3].coordinate.x
@test result.stations[4].coordinate.y ≈ result.stations[9].coordinate.y
@test result.stations[9].coordinate.y ≈ result.stations[7].coordinate.y
@test result.stations[6].coordinate.y ≈ result.stations[8].coordinate.y
@test result.stations[5].coordinate.y ≈ result.stations[6].coordinate.y

