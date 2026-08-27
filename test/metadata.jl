@testitem "NoMetadata" begin
    using SpaceDataModel: NoMetadata
    nm = NoMetadata()

    # Test keys operation
    @test keys(nm) == () == keys(NamedTuple())
    @test length(keys(nm)) == 0
    @test values(nm) == ()

    # Test haskey operation
    @test haskey(nm, "any_key") == false
    @test haskey(nm, :symbol_key) == false
    # Test get operation with default
    @test get(nm, "key", nothing) === nothing
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

@testitem "NoMetadata in model constructors" begin
    using SpaceDataModel: NoMetadata

    # Extra kwargs merge NoMetadata into a Dict; without them it stays NoMetadata.
    ds = Dataset("d", nothing; metadata = NoMetadata(), extra_key = "value")
    @test ds.metadata isa AbstractDict
    @test ds.metadata[:extra_key] == "value"
end

@testitem "OverlayDict" begin
    using SpaceDataModel: OverlayDict

    base = Dict("source" => "base", "base_only" => 1)
    d = OverlayDict{String, Any}(base)

    @test d["source"] == "base"
    @test_throws KeyError d[:source]
    @test !haskey(d, :base_only)
    @test get(d, :source, :fallback) == :fallback

    d["source"] = "overlay"
    d["overlay_only"] = 2

    @test d["source"] == "overlay"
    @test base["source"] == "base"
    @test keys(d) isa Base.KeySet
    @test length(d) == 3
    @test Dict(d) == Dict("source" => "overlay", "base_only" => 1, "overlay_only" => 2)
end
