using BenchmarkTools
using Dates
using SpaceDataModel

const SUITE = BenchmarkGroup()

# WindowedView benchmarks
let
    n = 10_000
    day = DateTime(2020, 1, 1)
    times = day .+ Second.(0:n-1)
    data1d = randn(n)
    data2d = randn(3, n)
    tr = TimeRanges(times[1], times[end], Second(100), Second(50))

    wv1d     = WindowedView(data1d, times, Second(30), Second(30))
    wv1d_tr  = WindowedView(data1d, times, tr)
    wv2d     = WindowedView(data2d, times, Second(30), Second(30))

    g = SUITE["WindowedView"] = BenchmarkGroup()
    g["getindex_1d"]          = @benchmarkable $wv1d[500]
    g["getindex_1d_tranges"]  = @benchmarkable $wv1d_tr[10]
    g["getindex_2d"]          = @benchmarkable $wv2d[500]
    g["collect_1d"]           = @benchmarkable collect($wv1d)
end
