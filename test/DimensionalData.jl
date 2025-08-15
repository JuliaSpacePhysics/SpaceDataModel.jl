@testitem "DimensionalData Extension Tests" begin
    using DimensionalData
    # Create test data
    A = DimArray(rand(10, 5), (X(1:10), Y(1:5)))
    A_mutable = rebuild(A, metadata=Dict())

    # Test with key-value pairs and keyword arguments
    @test_nowarn setmeta(A, "string" => "supported", description="velocity", calibrated=true)
    @test_throws ErrorException setmeta!(A, "string" => "supported", calibrated=true)
    @test_nowarn setmeta!(A_mutable, "string" => "supported", calibrated=true)
    @test A_mutable.metadata == Dict("string" => "supported", :calibrated => true)
    
    # Test with Dict
    meta_dict = Dict("string" => "supported", :calibrated => false)
    @test_nowarn setmeta(A, meta_dict)
    @test_nowarn setmeta(A_mutable, meta_dict)
    @test_nowarn setmeta!(A_mutable, meta_dict)
    @test A_mutable.metadata == meta_dict
end
