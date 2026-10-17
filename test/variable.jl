@testitem "AbstractDataVariable Broadcasting" begin
    using SpaceDataModel: AbstractDataVariable, DataVariable, coords, dims, times

    var = DataVariable([1.0, 2.0, 3.0]; metadata = Dict("istest" => true))
    result1 = var .+ 1
    @test result1 isa DataVariable
    @test parent(result1) == [2.0, 3.0, 4.0]
    @test size(var .+ ones(3, 2)) == (3, 2)
    using Dates
    ts = DateTime(2020) .+ Day.(0:2)
    v = DataVariable(rand(3, 1); time = 1 => ts, dims = (2 => [1.0],), coords = ((1, 2) => rand(3, 1), 1 => ["a", "b", "c"]))
    r = v .+ ones(1, 2, 4)  # extends axis 2 and appends axis 3
    @test times(r) == ts && dims(r, 2) == 1:2 && dims(r, 3) == 1:4 && only(coords(r)) == ((1,) => ["a", "b", "c"])
    v1 = DataVariable([1.0]; time = ts[1:1])
    @test_throws DimensionMismatch v1 .+ ones(3)
    v3 = DataVariable(rand(3); time = ts)
    @test times(v1 .+ v3) == times(DataVariable([1.0]) .+ v3) == ts
    # Results are those of the parent array
    @test DataVariable(fill(1.0)) .+ 1 === 2.0
end

@testitem "time dimension" begin
    using SpaceDataModel: hastimedim
    @test !hastimedim([1.0, 2.0])
    @test_throws ArgumentError SpaceDataModel.timedim([1.0, 2.0])
end

@testitem "rebuild" begin
    using SpaceDataModel: DataVariable, axiskeys, dims, hastimedim, name, rebuild, tdimnum, times
    using TimeseriesUtilities: tclip, tselect
    using Dates

    struct Source{T, N, A <: AbstractArray{T, N}} <: AbstractDataVariable{T, N}
        data::A
        time::Vector{DateTime}
        meta::Dict{String, Any}
    end
    SpaceDataModel.tdimnum(::Source) = 1
    SpaceDataModel.dims(v::Source, i::Integer) = i == 1 ? v.time : axes(v, i)
    SpaceDataModel.name(::Source) = "B"

    ts = DateTime(2020) .+ Day.(0:2)
    A = [1.0 2.0; 3.0 4.0; 5.0 6.0]
    v = Source(A, ts, Dict{String, Any}("units" => "nT"))
    # time moved to the last axis
    @test tdimnum(rebuild(v, permutedims(A), (Val(2), Val(1)))) == 2

    energy = DataVariable([10.0, 20.0]; metadata = Dict("name" => "energy"))
    w = DataVariable(A; time = 1 => ts, dims = (2 => energy,))
    @test name(dims(rebuild(w, A[2:3, :], (Val(1) => ts[2:3], Val(2))), 2)) == "energy"
    # time-varying dimensions follow selections, in either axis order; new times drop them
    E = [10.0 20.0; 11.0 21.0; 12.0 22.0]
    tv = DataVariable(A; time = 1 => ts, dims = (2 => E,))
    @test dims(tselect(tv, ts[2]), 1) == E[2, :]
    @test dims(tclip(DataVariable(permutedims(A); time = 2 => ts, dims = (1 => permutedims(E),)), ts[2], ts[3]), 1) == permutedims(E[2:3, :])
    @test dims(rebuild(tv, permutedims(A), (Val(2), Val(1))), 1) == permutedims(E)  # in the new axis order
    r = rebuild(tv, A[2:3, :], 1, ts[2:3])
    @test times(r) == ts[2:3] && dims(r, 2) == 1:2
    @test_throws DimensionMismatch DataVariable(A; time = 1 => ts[1:2])
    @test_throws DimensionMismatch DataVariable(A; time = 2 => ts, dims = (1 => E,))
    @test_throws ArgumentError DataVariable(A; time = ts)  # which axis?
    @test_throws ArgumentError DataVariable(A; time = 1 => ts, dims = (1 => ts,))
    @test_throws ArgumentError DataVariable(A; dims = (2 => [1, 2], 2 => [3, 4]))
    # a literal time axis is inferred
    timelast(A, t) = DataVariable(A; time = 2 => t, dims = (1 => [10.0, 20.0],))
    @test tdimnum(@inferred timelast(permutedims(A), ts)) == 2

    # indexing slices the dimensions
    r = v[2:3, :]
    @test times(r) == ts[2:3] && units(r) == "nT" && name(r) == "B"
    @test times(view(v, [1, 3], 2)) == ts[[1, 3]]
    @test !hastimedim(v[2, :])
    @test dims(v[:, 2:2], 2) == 1:1  # a plain axis stays plain, renumbered
    @test times(v .+ 1) == ts && units(v .+ 1) == "nT"
    r2 = r[1:1, :]
    r2["units"] = "pT"
    @test units(r) == units(v) == "nT"
    view(r, 1:1, :)["units"] = "pT"
    @test units(r) == "pT" && units(v) == "nT"
end

@testitem "same-shape results and slices infer" begin
    using SpaceDataModel: DataVariable
    using Dates
    v = DataVariable(rand(3, 100); time = 2 => DateTime(2020) .+ Day.(0:99), dims = (1 => rand(3, 100),))  # time-varying dimension
    for f in (similar, copy, x -> map(abs, x), x -> x .* 2, x -> x .+ ones(3), x -> view(x, :, 1), x -> view(x, :, 1:2))
        @test isconcretetype(only(Base.return_types(f, (typeof(v),))))
    end
    # any `similar` shape is allowed, so only a small union of concrete types
    @test all(isconcretetype, Base.uniontypes(only(Base.return_types(similar, (typeof(v), Type{Float32}, Dims{2})))))
end

@testitem "operations infer" begin
    using SpaceDataModel: DataVariable
    using TimeseriesUtilities: mapsamples, tderiv, tinterp, tmean, tshift
    using Dates
    ts = DateTime(2020) .+ Second.(0:99)
    v = DataVariable(rand(100, 3); time = 1 => ts, coords = (2 => ["x", "y", "z"],))
    # new times of another type than `ts` (a range, a view, durations) must not make the result a union;
    # `ts` is an argument because the test body's variables are untyped globals
    ops = (
        (x, _) -> tmean(x), (x, _) -> mapsamples(s -> s .* [1 2], x), (x, _) -> tderiv(x),
        (x, t) -> tinterp(x, t[1]:Second(2):t[9]), (x, t) -> tshift(x, t[1]), (x, _) -> tmean(x, Second(10)),
    )
    VERSION >= v"1.11" && @testset "op $i" for (i, op) in enumerate(ops)
        @test @inferred(op(v, ts)) isa DataVariable
    end
end

@testitem "coordinates" begin
    using SpaceDataModel: DataVariable, coords, dims, rebuild, rekey, times
    using TimeseriesUtilities: tmean
    using Dates
    ts = DateTime(2020) .+ Day.(0:2)
    E = [10.0 11.0 12.0; 20.0 21.0 22.0]  # time-varying energies
    lab = 1 => ["lo", "hi"]
    v = DataVariable(rand(2, 3); time = 2 => ts, dims = (1 => E,), coords = (lab,))
    @test only(coords(v[[2, 1], :])) == ((1,) => ["hi", "lo"])
    @test only(coords(v[2, :])) == ((1,) => E[2, :])  # labels dropped
    # a time-varying coordinate of a dropped axis runs along time
    @test dims(v[2, 2:3], 1) == ts[2:3] && last(only(coords(v[2, 2:3]))) == E[2, 2:3]
    # reductions keep coordinates constant along the reduced axis
    @test dims(tmean(v), 1) == 1:2 && last(only(coords(tmean(v)))) == ["lo", "hi"]
    @test isequal(dims(tmean(DataVariable(rand(2, 3); time = 2 => ts, dims = (1 => [10.0 10.0 10.0; NaN NaN NaN],))), 1), [10.0, NaN])
    @test size(tmean(DataVariable(zeros(2, 0); time = 2 => DateTime[], dims = (1 => zeros(2, 0),)))) == (2,)
    B = rand(2, 4, 3)
    p = rebuild(DataVariable(rand(2, 4, 3); time = 3 => ts, coords = ((1, 2, 3) => B,)), rand(3, 2, 4), (Val(3), Val(1), Val(2)))
    @test only(coords(p)) == ((1, 2, 3) => permutedims(B, (3, 1, 2)))
    # relabelling keeps them
    r = rekey(v, 1, ["a", "b"])
    @test dims(r, 1) == ["a", "b"] && last(only(coords(r))) == ["lo", "hi"]
    @test last(only(coords(rebuild(v, rand(2, 3), 2, ts .+ Hour(1))))) == ["lo", "hi"]
    # explicit keys equal to the axis are a coordinate, sliced with the data
    @test dims(DataVariable(rand(3); dims = (1 => 1:3,))[2:3], 1) == 2:3
    @test dims(DataVariable(rand(3, 2); time = 2 => ts[1:2], dims = (1 => 1.0:3.0,))[2:3, :], 1) == 2.0:3.0
    P = rand(3, 2)
    @test only(coords(DataVariable(rand(2, 3); coords = ((2, 1) => P,)))) == ((1, 2) => permutedims(P))
    @test_throws DimensionMismatch DataVariable(rand(2, 3); time = 2 => ts, coords = (1 => ["a"],))
end

@testitem "times and slices infer" begin
    using SpaceDataModel: DataVariable, times
    using Dates
    v = DataVariable(rand(3, 4); time = 2 => DateTime(2020) .+ Day.(0:3), dims = (1 => ["x", "y", "z"],))
    @test (@inferred times(v)) isa Vector{DateTime}
    @test times(@inferred v[2:3, 2:3]) == times(v)[2:3]
    @test (@inferred v[1, :]) isa DataVariable
end

@testitem "indexing with CartesianIndex or trailing integers" begin
    using SpaceDataModel: DataVariable, times
    using Dates
    ts = DateTime(2020) .+ Day.(0:2)
    v = DataVariable([1.0 2.0 3.0; 4.0 5.0 6.0]; time = 2 => ts)
    @test times(v[CartesianIndex(2), 2:3]) == times(v[2, 2:3, 1]) == ts[2:3]
    @test v[2:3] isa Vector  # linear indexing
    @test v[1, :, :] isa Matrix
end

@testitem "dims ignores a non-AbstractDataVariable dims field" begin
    # `Base.ReshapedArray` stores its size in a `dims` field
    @test SpaceDataModel.dims(reshape(view(collect(1:6), :), 2, 3), 1) == 1:2
end

@testitem "units follows the metadata schema" begin
    using SpaceDataModel: DataVariable
    @test units(DataVariable([1.0]; metadata = Dict("CATDESC" => "B", "UNITS" => "nT"))) == "nT"
    @test units(DataVariable([1.0]; metadata = Dict("units" => "m/s"))) == "m/s"
end
