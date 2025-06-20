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

    # we can see their memory usages are the same
    @test Base.sizeof(x1) == Base.sizeof(x2)
    @test Base.summarysize(x1) == Base.summarysize(x2)
    @test isbits(x1)
    @test isbits(x2)

    @test isnothing(getcsys(data))
    @test getcsys(x1) == GEO()
    @test getcsys(x2) == GEO()
    @test getcsys(GEO) == GEO()
    @test getcsys(GEO()) == GEO()
    @test String(GEO) == "GEO"
end
