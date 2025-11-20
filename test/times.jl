@testitem "cadence" begin
    using Dates
    using SpaceDataModel: cadence, ≃

    # AbstractRange - returns step directly
    @test cadence(1:10) == 1
    @test cadence(0.0:0.5:10.0) == 0.5
    @test cadence(Nanosecond(1):Nanosecond(1):Nanosecond(100)) == Nanosecond(1)

    # Vector{Float64}
    times = collect(0.0:1.0:100.0)
    @test cadence(times) == 1.0
    @test cadence(Float64, times) == 1.0

    # Approximately uniform sampling
    times_noisy = times .+ 1.0e-6 .* randn(length(times))
    @test ≃(cadence(times_noisy), 1.0; rtol = 1.0e-3)

    # Non-uniform sampling should error
    times_bad = [0.0, 1.0, 3.0, 4.0]
    @test_throws AssertionError cadence(times_bad)
    @test cadence(times_bad; check = false) ≈ 4.0 / 3

    # Dates support
    dt_range = DateTime(2020):Hour(1):DateTime(2020, 1, 2)
    @test cadence(dt_range) == Hour(1)

    ns_times = Nanosecond.(0:1_000_000_000:10_000_000_000)
    @test cadence(ns_times) == Nanosecond(1_000_000_000)
    @test cadence(Float64, ns_times) == 1.0
end
