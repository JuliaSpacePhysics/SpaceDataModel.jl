using Chairmarks
using Dates
using SpaceDataModel.Times

function slow_resolution(times; rtol = 1.0e-3, check = true)
    dts = diff(times)
    check && (all(d -> ≃(d, dts[1]; rtol), dts) || error("Data is not approximately uniformly sampled."))
    return dts[1]
end

# Generate large approximately sampled times with small noise
function generate_approx_times(n, dt, noise_level = 1.0e-5)
    base = range(0.0, step = dt, length = n)
    return collect(base) .+ noise_level .* randn(n)
end

function generate_approx_times2(n, dt, noise_level = 1.0e-5)
    base = range(0.0, step = dt, length = n)
    return 1.0e9 .* Nanosecond.(collect(base)) .+ round.(Int64, noise_level .* randn(n) .* 1.0e9) .* Nanosecond(1)
end

# Benchmark suite
function run_resolution_benchmarks()
    sizes = [10^3, 10^4, 10^5, 10^6]
    dt = 1.0
    println("Resolution Benchmark")
    println("="^60)

    for n in sizes
        times_range = range(0.0, step = dt, length = n)
        for f in [generate_approx_times, generate_approx_times2]
            times = f(n, dt)
            b_range = @b cadence($times_range) samples = 10 evals = 3
            b_check = @b cadence($times; check = true) samples = 10 evals = 3
            b_check2 = @b slow_resolution($times; check = true) samples = 10 evals = 3
            println("\nn = $(n):")
            @info "b_check" b_check b_check2 b_range
        end
    end

    return
end


run_resolution_benchmarks()
