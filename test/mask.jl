@testitem "mask_invalid!" begin
    using SpaceDataModel: mask_invalid!, mask_invalid
    using Dates

    x = Int8[1, 2]
    @test mask_invalid(x) == x
    @test eltype(mask_invalid(x)) === Float32

    A = Float32[1 2; 3 4; 5 6]
    @test isnan.(mask_invalid!(copy(A); validmin = [1, 4], validmax = [3, 6], dims = 2)) == Bool[0 1; 0 0; 1 0]
    @test isnan.(mask_invalid!(copy(A); validmin = [1, 3, 5], validmax = [1, 3, 5], dims = 1)) == Bool[0 1; 0 1; 0 1]

    B = [1.0, NaN, -1.0e31]
    @test mask_invalid!(B; fillval = [-1.0e31], dims = 1) === B
    @test isnan(B[3])

    I = mask_invalid!(Int16[-1, 3, 40]; fillval = Int16(-1), validmin = 0, validmax = 32, dims = 1)
    @test I isa Vector{Float32}
    @test isequal(I, Float32[NaN, 3, NaN])

    @test isnan(mask_invalid!(Float32[-1.0f31]; fillval = -1.0e31)[1])
    @test_throws ArgumentError mask_invalid!([1.0, 2.0]; validmax = [1.0, 2.0])

    t = [DateTime(2000)]
    @test mask_invalid!(t; fillval = DateTime(2000), dims = 1) === t
end
