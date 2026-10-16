@testitem "TimeseriesUtilities operations agree with Timed" begin
    using TimeseriesUtilities
    using TimeseriesUtilities: unwrap
    using SpaceDataModel: DataVariable

    struct Source{T, N, A <: AbstractArray{T, N}} <: AbstractDataVariable{T, N}
        data::A
        time::Vector{Float64}
        meta::Dict{String, Any}
    end
    SpaceDataModel.tdimnum(::Source) = 1
    SpaceDataModel.dims(v::Source, i::Integer) = i == 1 ? v.time : axes(v, i)

    A = [1.0 10.0; NaN 20.0; 3.0 30.0; 4.0 400.0; 5.0 50.0]
    t = [0.0, 1.0, 2.0, 4.0, 5.0]
    meta = Dict{String, Any}("units" => "nT")
    backends = (
        Source = (Source(A, t, meta), Timed(A, t; dim = 1)),
        time_last = (DataVariable(permutedims(A); time = 2 => t, metadata = meta), Timed(permutedims(A), t; dim = 2)),
    )
    # One op per `rebuild` method; TimeseriesUtilities tests the ops themselves.
    ops = (
        x -> tsmooth(x, 2.0),
        x -> tclip(x, 1.0, 4.0),
        x -> tshift(x, 1.0),
        tmean,
        x -> mapsamples(sum, x),
    )
    @testset "op $i on $name" for (i, op) in enumerate(ops), (name, (x, timed)) in pairs(backends)
        ref = op(timed)
        r = op(x)
        @test isequal(unwrap(r), unwrap(ref))
        ref isa Timed && @test r isa DataVariable && times(r) == times(ref) && units(r) == "nT"
    end

    energy = DataVariable([10.0, 20.0]; metadata = Dict("name" => "energy"))
    r = tclip(DataVariable(A; time = 1 => t, dims = (2 => energy,), metadata = meta), 15.0, 25.0; dim = "energy")
    @test isequal(unwrap(r), A[:, 2:2]) && times(r) == t
end

@testitem "depend_1 of a vector without a time dimension" begin
    using SpaceDataModel: DataVariable, depend_1, mask_invalid
    using Dates
    @test depend_1(DataVariable([1.0, 2.0, 3.0]; dims = (1 => ["x", "y", "z"],))) == ["x", "y", "z"]
    ts = DateTime(2020) .+ Day.(0:1)
    v = DataVariable([1.0 2.0 3.0; 4.0 5.0 6.0]; time = 1 => ts, metadata = Dict("CATDESC" => "B", "VALIDMAX" => [0.0, 5.0, 5.0]))
    @test isequal(mask_invalid(v[1, :]), [NaN, 2.0, 3.0])  # a single record
end
