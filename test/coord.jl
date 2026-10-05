@testitem "CoordinateSystem" begin
    # We demonstrate two ways to implement a CoordinateVector
    import SpaceDataModel: getcsys

    struct GEO <: AbstractCoordinateSystem end
    struct CoordinateVector{D, T} <: AbstractCoordinateVector
        data::D
        csys::T
    end

    struct GEOVector{D} <: AbstractCoordinateVector
        data::D
    end
    getcsys(x::GEOVector) = GEO()

    data = (1.0, 2.0, 3.0)

    x1 = CoordinateVector(data, GEO())
    x2 = GEOVector(data)

    @test isnothing(getcsys(data))
    @test getcsys(x1) == GEO()
    @test getcsys(x2) == GEO()
end
