@testitem "AbstractDataVariable Broadcasting" begin
    using SpaceDataModel: AbstractDataVariable, DataVariable
    using Base.Broadcast: ArrayStyle, Broadcasted

    # Test BroadcastStyle
    var = DataVariable([1.0, 2.0, 3.0], Dict("istest" => true))
    @test Base.BroadcastStyle(typeof(var)) == ArrayStyle{AbstractDataVariable}()

    show(stdout, [var])
    # Test broadcasting operations
    result1 = var .+ 1
    @test result1 isa DataVariable
    @test parent(result1) == [2.0, 3.0, 4.0]
end

@testitem "Field-name defaults only for AbstractDataVariable" begin
    using SpaceDataModel: dim, times
    using Dates
    t = DateTime(2020) .+ Hour.(0:2)

    struct Fields{T, N, A <: AbstractArray{T, N}, D} <: AbstractArray{T, N}
        data::A
        dims::D
        times::Vector{DateTime}
    end
    Base.size(x::Fields) = size(x.data)
    Base.getindex(x::Fields, i::Int...) = x.data[i...]

    struct Var{T, N, A <: AbstractArray{T, N}, D} <: AbstractDataVariable{T, N}
        data::A
        dims::D
        times::Vector{DateTime}
    end
    SpaceDataModel.tdimnum(::Var) = 1

    x = Fields(rand(3), (t,), t)
    v = Var(rand(3), (t,), t)
    @test dim(x, 1) == Base.OneTo(3)
    @test dim(v, 1) === t
    @test times(v) === t
    @test_throws ArgumentError times(x)
end
