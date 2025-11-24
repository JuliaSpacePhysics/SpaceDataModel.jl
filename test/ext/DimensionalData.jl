@testitem "DimensionalData Metadata" begin
    using DimensionalData
    # Create test data
    A = DimArray(rand(10, 5), (X(1:10), Y(1:5)))
    A_mutable = rebuild(A, metadata = Dict())

    # Test with key-value pairs and keyword arguments
    @test_nowarn setmeta(A, "string" => "supported", description = "velocity", calibrated = true)
    @test_throws ErrorException setmeta!(A, "string" => "supported", calibrated = true)
    @test_nowarn setmeta!(A_mutable, "string" => "supported", calibrated = true)
    @test A_mutable.metadata == Dict("string" => "supported", :calibrated => true)

    # Test with Dict
    meta_dict = Dict("string" => "supported", :calibrated => false)
    @test_nowarn setmeta(A, meta_dict)
    @test_nowarn setmeta(A_mutable, meta_dict)
    @test_nowarn setmeta!(A_mutable, meta_dict)
    @test A_mutable.metadata == meta_dict
end

@testitem "DimensionalData: general methods" begin
    using DimensionalData
    using SpaceDataModel: name, meta, dim, timedim, times, tmin, tmax, unwrap

    x = rand(X(3), Y(4), Ti(5))
    @test meta(x) == DimensionalData.NoMetadata()
    @test dim(x, 1) == X(1:3)
    @test dim(x, 2) == Y(1:4)
    @test dim(x, 3) == Ti(1:5)
    @test dim(x, :Ti) == Ti(1:5)
    @test dim(x, :X) == X(1:3)
    @test_throws ErrorException dim(x, :time)

    @test string(name(x)) == ""
    @test unwrap(Ti(view([1, 2, 3, 4, 5], 2:3))) == view(1:5, 2:3)

    @testset "TimeSeriesAPI" begin
        using SpaceDataModel: tdimnum
        x = rand(X(3), Ti(5), Z(2))
        @test tdimnum(x) == 2
        @test timedim(x) == Ti([1, 2, 3, 4, 5])
        @test times(x) == [1, 2, 3, 4, 5]
        @test tmin(x) == 1
        @test tmax(x) == 5
        @test unwrap(timedim(x)) == 1:5
        @test name(timedim(x)) == :Ti

        x = rand(X(3), Dim{:time}(5), Z(2))
        @test tdimnum(x) == 2
        @test (@allocated tdimnum(x)) == 0
    end
end
