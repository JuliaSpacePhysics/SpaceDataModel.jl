@testitem "TimeRanges" begin
    using Dates
    using SpaceDataModel: TimeRanges
    using Chairmarks

    start = DateTime("2010-03-04T00:10:00")
    stop = DateTime("2010-03-04T01:20:00")

    tranges = TimeRanges(start, stop, Hour(1), Second(12))
    fragments = collect(tranges)

    @test length(tranges) == 2
    @test length(fragments) == 2
    @test (@b collect($tranges)).allocs <= 2

    @test first(tranges) == fragments[1] == (DateTime("2010-03-04T00:10:00"), DateTime("2010-03-04T00:10:12"))
    @test fragments[2] == (DateTime("2010-03-04T01:10:00"), DateTime("2010-03-04T01:10:12"))

    tranges = TimeRanges(start, stop)
    @test length(tranges) == 1
end

@testitem "ContinuousTimeRanges" begin
    using Dates
    using SpaceDataModel: ContinuousTimeRanges
    using Chairmarks

    times = [
        Time(0, 0, 0),
        Time(1, 0, 0),
        Time(2, 0, 0),
        Time(6, 0, 0), # Gap of 4 hours
        Time(7, 0, 0),
        Time(8, 0, 0),
        Time(12, 0, 0),
        Time(13, 0, 0),
    ]

    ctr = ContinuousTimeRanges(times, Hour(2))
    ranges = collect(ctr)

    @test eltype(ctr) != Any
    @test (@b collect($ctr)).allocs <= 2

    @test length(ranges) == 3
    @test ranges[1] == (Time(0, 0, 0), Time(2, 0, 0))
    @test ranges[2] == (Time(6, 0, 0), Time(8, 0, 0))
    @test ranges[3] == (Time(12, 0, 0), Time(13, 0, 0))
end
