coord1 = GeoCoordinate(1, 2)
coord2 = GeoCoordinate(1, 3)

station1 = GeoStation(1, coord1, "test_2", false)
station2 = GeoStation(2, coord2, "test", false)
label_node3 = GeoStation(3, coord2, "test", true)
label_node4 = GeoStation(4, coord2, "test", true)

line1 = Line("S1")
line2 = Line("DummyEdge2")
line3 = Line("DummyEdge3")
edge = ProcessedEdge(station1, station2, line1, 0, 1, false)


edge2 = ProcessedEdge(station1, label_node3, line2, 0, 7, true)
edge3 = ProcessedEdge(station2, label_node4, line2, 0, 7, true)


transit_map = InputGraph([station1, station2, label_node3, label_node4],
    [edge, edge2, edge3],
    [line1, line2, line3])



result = optimize(GLPKSolverMIP(msg_lev = 3), transit_map)

@test result.stations[1].coordinate.y ≈ result.stations[2].coordinate.y

# label one should not be in sector 2
@test !(result.stations[3].coordinate.x ≈ result.stations[2].coordinate.x &&
    result.stations[3].coordinate.y > result.stations[2].coordinate.y)


# label one should not be in sector 6
@test !(result.stations[3].coordinate.x ≈ result.stations[2].coordinate.x &&
    result.stations[3].coordinate.y < result.stations[2].coordinate.y)

# @test result.stations[1].coordinate.y ≈ result.stations[2].coordinate.y
# @test result.stations[2].coordinate.y ≈ result.stations[3].coordinate.y
# @test result.stations[2].coordinate.x ≈ result.stations[4].coordinate.x
# @test result.stations[2].coordinate.x ≈ result.stations[5].coordinate.x
# @test result.stations[4].coordinate.y > result.stations[5].coordinate.y

# @test result.stations[6].coordinate.x ≈ result.stations[9].coordinate.x
# @test result.stations[6].coordinate.x ≈ result.stations[1].coordinate.x
# @test result.stations[7].coordinate.x ≈ result.stations[8].coordinate.x
# @test result.stations[7].coordinate.x ≈ result.stations[3].coordinate.x
# @test result.stations[4].coordinate.y ≈ result.stations[9].coordinate.y
# @test result.stations[9].coordinate.y ≈ result.stations[7].coordinate.y
# @test result.stations[6].coordinate.y ≈ result.stations[8].coordinate.y
# @test result.stations[5].coordinate.y ≈ result.stations[6].coordinate.y

