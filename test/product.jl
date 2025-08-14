@testitem "Product Construction" begin
    using SpaceDataModel: Product, func, NoMetadata

    # Test basic construction with minimal parameters
    p1 = Product([1, 2, 3])
    @test parent(p1) == [1, 2, 3]
    @test func(p1) === identity
    @test p1.name == ""
    @test p1.metadata isa NoMetadata  # NoMetadata() becomes Dict when merged with kwargs

    # Test construction with transformation function
    p2 = Product([1, 2, 3], x -> x .* 2)
    @test parent(p2) == [1, 2, 3]
    @test func(p2)([1, 2, 3]) == [2, 4, 6]

    # Test construction with name
    p3 = Product([1, 2, 3]; name="test_data")
    @test p3.name == "test_data"

    # Test construction with metadata
    p4 = Product([1, 2, 3]; metadata=Dict("units" => "m/s"))
    @test p4.metadata["units"] == "m/s"

    # Test construction with kwargs that become metadata
    p5 = Product([1, 2, 3]; units="m/s", description="velocity")
    @test p5.metadata isa AbstractDict
    @test p5.metadata[:units] == "m/s"
    @test p5.metadata[:description] == "velocity"

    # Test full constructor
    p6 = Product([1, 2, 3], x -> x .+ 1, "full_test", Dict("key" => "value"))
    @test parent(p6) == [1, 2, 3]
    @test func(p6)([1, 2, 3]) == [2, 3, 4]
    @test p6.name == "full_test"
    @test p6.metadata["key"] == "value"
end

@testitem "Product Methods" begin
    using SpaceDataModel: Product
    p1 = Product([1, 4, 9], x -> sqrt.(x))
    @test all(p1 .== [1, 4, 9])
    @test_nowarn sprint(show, p1)
end

@testitem "Product Function Application and Composition" begin
    using SpaceDataModel: Product

    p1 = Product([1, 2, 3], x -> x .* 2)
    @test p1() == [2, 4, 6]

    # Test calling with additional arguments
    p2 = Product([1, 2, 3], (x, y) -> x .+ y)
    @test p2(10) == [11, 12, 13]

    # Test with identity transformation
    p3 = Product([1, 2, 3])
    @test p3() == [1, 2, 3]

    # Test composition with function on left
    p1 = Product([1, 2, 3], x -> x .* 2)
    p2 = Product([1, 2, 3], x -> x .+ 1)
    p3 = (x -> x .+ 1) ∘ p1
    @test p3() == [3, 5, 7]  # (x * 2) + 1

    # Test composition with function on right
    p4 = p1 ∘ (x -> x .+ 1)
    @test p4() == [4, 6, 8]  # (x + 1) * 2

    # Test composition between products
    p5 = p1 ∘ p2
    @test p5() == [4, 6, 8]  # (x + 1) * 2
end

@testitem "Product Setting Operations" begin
    using SpaceDataModel: Product, set

    # Test immutable set operations
    p1 = Product([1, 2, 3]; name="original")

    # Test setting name
    p2 = set(p1; name="new_name")
    @test p2.name == "new_name"
    @test p1.name == "original"  # Original unchanged

    # Test setting data
    data = [4, 5, 6]
    @test set(p1; data)() == data
    @test set(p1, data)() == data

    # Test setting metadata
    p4 = set(p1; units="m/s", description="velocity")
    @test p4.metadata[:units] == "m/s"
    @test p4.metadata[:description] == "velocity"
end