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

    # getindex
    @test tranges[2] == fragments[2]

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

@testitem "WindowedView" begin
    using Dates
    using SpaceDataModel: WindowedView, TimeRanges
    using Chairmarks

    day = Date(2020, 1, 1)
    times = day .+ [Time(i, 0, 0) for i in 0:9]
    data = collect(0:9)

    # before/after form: window around each coord point
    wv = WindowedView(data, times, Hour(1), Hour(1))
    @test length(wv) == length(times)
    @test wv[1] == view(data, 1:2) == 0:1
    @test wv[2] == view(data, 1:3) == 0:2
    @test wv[4] == view(data, 3:5) == 2:4

    # no performance regression for 1D
    @test (@b $wv[4]).allocs == 0

    # Composable with TimeRanges
    tr = TimeRanges(day + Time(0, 0, 0), day + Time(9, 0, 0), Hour(3), Hour(2))
    wv2 = WindowedView(data, times, tr)
    @test length(wv2) == length(tr)
    @test wv2[1] == view(data, 1:3)
    @test wv2[2] == view(data, 4:6)
    @test wv2[3] == view(data, 7:9)

    # Multi-dimensional: (3, n_times) matrix, time along dim=2
    data2d = reshape(1:30, 3, 10)
    wv3 = WindowedView(data2d, times, Hour(1), Hour(1); dim = 2)
    @test wv3[1] == view(data2d, :, 1:2)
    @test wv3[4] == view(data2d, :, 3:5)
    @test (@b $wv3[4]).allocs == 0

    # Multi-dimensional: (n_times, 3) matrix, time along dim=1
    data2d_t = reshape(1:30, 10, 3)
    wv4 = WindowedView(data2d_t, times, Hour(1), Hour(1); dim = 1)
    @test wv4[1] == view(data2d_t, 1:2, :)
    @test wv4[4] == view(data2d_t, 3:5, :)
end
