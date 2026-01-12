@testitem "NoMetadata" begin
    using SpaceDataModel: NoMetadata
    nm = NoMetadata()

    # Test keys operation
    @test keys(nm) == () == keys(NamedTuple())
    @test length(keys(nm)) == 0
    @info values(nm)

    # Test haskey operation
    @test haskey(nm, "any_key") == false
    @test haskey(nm, :symbol_key) == false
    # Test get operation with default
    @test get(nm, "key", nothing) == nothing
end

@testitem "NoMetadata Merging Operations" begin
    using SpaceDataModel: NoMetadata

    nm = NoMetadata()

    # Test merging with Dict
    dict1 = Dict("key1" => "value1", "key2" => "value2")
    merged1 = merge(nm, dict1)
    @test merged1 == dict1
    @test merged1 !== dict1  # Should be a copy
    @test merge(nm, Dict()) == nm # Test merging with empty Dict
    @test merge(nm, nm) == nm # Test merging with NoMetadata
    @test merge(nm, dict1, nm) == dict1
end

@testitem "NoMetadata Type Conversions" begin
    using SpaceDataModel: NoMetadata
    nm = NoMetadata()
    # Test conversion to NamedTuple
    @test NamedTuple(nm) == (;)
    # Test conversion to Dict
    @test Dict(pairs(nm)) == Dict()
end

@testitem "NoMetadata in Product Context" begin
    using SpaceDataModel: NoMetadata, Product

    # Test that NoMetadata works correctly in Product constructor
    nm = NoMetadata()

    # When kwargs are provided, NoMetadata gets merged into Dict
    p2 = Product([1, 2, 3]; metadata = nm, extra_key = "value")
    @test p2.metadata isa AbstractDict
    @test p2.metadata[:extra_key] == "value"

    # Test default behavior
    p3 = Product([1, 2, 3])
    @test p3.metadata isa NoMetadata
end
