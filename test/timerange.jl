@testitem "TimeRanges" begin
    using Dates
    using SpaceDataModel: TimeRanges

    start = DateTime("2010-03-04T00:10:00")
    stop = DateTime("2010-03-04T01:20:00")

    tranges = TimeRanges(start, stop, Hour(1), Second(12))
    fragments = collect(tranges)

    @test length(tranges) == 2
    @test length(fragments) == 2

    @test first(tranges) == fragments[1] == (DateTime("2010-03-04T00:10:00"), DateTime("2010-03-04T00:10:12"))
    @test fragments[2] == (DateTime("2010-03-04T01:10:00"), DateTime("2010-03-04T01:10:12"))

    tranges = TimeRanges(start, stop)
    @test length(tranges) == 1
end
