#                     5
#                     |
# 6 -> 7 -> 4 -> 8 -> 9
#                     |
#           1 -> 2 -> 3

s1 = EuclideanStation(1, EuclideanCoordinate(3, 1), "test", false)
s2 = EuclideanStation(2, EuclideanCoordinate(4, 1), "test", false)
s3 = EuclideanStation(3, EuclideanCoordinate(5, 1), "test", false)
s5 = EuclideanStation(5, EuclideanCoordinate(5, 4), "test", false)


s9 = EuclideanStation(9, EuclideanCoordinate(5, 3), "test", false)


s6 = EuclideanStation(6, EuclideanCoordinate(1, 3), "test", false)
s7 = EuclideanStation(7, EuclideanCoordinate(2, 3), "test", false)
s4 = EuclideanStation(4, EuclideanCoordinate(3, 3), "test", false)
s8 = EuclideanStation(8, EuclideanCoordinate(4, 3), "test", false)


line1 = Line("S1")
line2 = Line("S2")
e1 = ProcessedEdge(s1, s2, line1, 0, 1, false)
e2 = ProcessedEdge(s2, s3, line1, 0, 1, false)
e3 = ProcessedEdge(s3, s9, line1, 2, 1, false)
e4 = ProcessedEdge(s9, s5, line1, 2, 1, false)

e5 = ProcessedEdge(s6, s7, line2, 0, 1, false)
e6 = ProcessedEdge(s7, s4, line2, 0, 1, false)
e7 = ProcessedEdge(s4, s8, line2, 0, 1, false)
e8 = ProcessedEdge(s8, s9, line2, 0, 1, false)
e9 = ProcessedEdge(s9, s5, line2, 0, 1, false)
transit_map = InputGraph([s1, s2, s3, s4, s5,
                          s6, s7, s8, s9],
    [e1, e2, e3, e4,
     e5, e6, e7, e8, e9],
    [line1, line2])


reduced_map = reduce_transitmap(transit_map)

@test length(reduced_map.stations) == 4
@test length(reduced_map.edges) == 4

