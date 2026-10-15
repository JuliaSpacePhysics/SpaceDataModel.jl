@testitem "AbstractDataVariable Broadcasting" begin
    using SpaceDataModel: AbstractDataVariable, DataVariable

    var = DataVariable([1.0, 2.0, 3.0], Dict("istest" => true))
    result1 = var .+ 1
    @test result1 isa DataVariable
    @test parent(result1) == [2.0, 3.0, 4.0]
    @test size(var .+ ones(3, 2)) == (3, 2)
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
    @test tdimnum(rebuild(v, permutedims(A), (Val(2), Val(1)), (1:2, ts))) == 2

    energy = DataVariable([10.0, 20.0], Dict("name" => "energy"))
    w = DataVariable(A, (ts, energy), 1, Dict())
    @test name(dims(rebuild(w, A[2:3, :], (Val(1), Val(2)), (ts[2:3], axiskeys(w, 2))), 2)) == "energy"
    # time-varying dimensions follow selections, in either axis order; new times drop them
    E = [10.0 20.0; 11.0 21.0; 12.0 22.0]
    tv = DataVariable(A, (ts, E), 1, Dict())
    @test dims(tselect(tv, ts[2]), 1) == E[2, :]
    @test dims(tclip(DataVariable(permutedims(A), (permutedims(E), ts), 2, Dict()), ts[2], ts[3]), 1) == permutedims(E[2:3, :])
    r = rebuild(tv, A[2:3, :], 1, ts[2:3])
    @test times(r) == ts[2:3] && dims(r, 2) == 1:2
    @test_throws DimensionMismatch DataVariable(A, (ts[1:2], 1:2), 1, Dict())
    @test_throws DimensionMismatch DataVariable(A, (ts, E), 2, Dict())

    # indexing slices the dimensions
    r = v[2:3, :]
    @test times(r) == ts[2:3] && units(r) == "nT" && name(r) == "B"
    @test times(view(v, [1, 3], 2)) == ts[[1, 3]]
    @test !hastimedim(v[2, :])
    @test times(v .+ 1) == ts && units(v .+ 1) == "nT"
    r2 = r[1:1, :]
    r2["units"] = "pT"
    @test units(r) == units(v) == "nT"
end

@testitem "indexing with CartesianIndex or trailing integers" begin
    using SpaceDataModel: DataVariable, times
    using Dates
    ts = DateTime(2020) .+ Day.(0:2)
    v = DataVariable([1.0 2.0 3.0; 4.0 5.0 6.0], (1:2, ts), 2, Dict())
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
    @test units(DataVariable([1.0], Dict("CATDESC" => "B", "UNITS" => "nT"))) == "nT"
    @test units(DataVariable([1.0], Dict("units" => "m/s"))) == "m/s"
end
