@testitem "mask_invalid!" begin
    using SpaceDataModel: mask_invalid!, mask_invalid, ValidityChecks
    using Dates

    A = Float32[1 2; 3 4; 5 6]
    @test isnan.(mask_invalid(A, ValidityChecks(Float32, nothing, [1, 4], [3, 6]), 2)) == Bool[0 1; 0 0; 1 0]
    @test isnan.(mask_invalid(A, ValidityChecks(Float32, nothing, [1, 3, 5], [1, 3, 5]))) == Bool[0 1; 0 1; 0 1]

    B = [1.0, -1.0e31]
    @test mask_invalid!(B, B, ValidityChecks(Float64, [-1.0e31], nothing, nothing)) === B
    @test isnan(B[2])

    I = mask_invalid(Int16[-1, 3, 40], ValidityChecks(Int16, Int16(-1), 0, 32))
    @test I isa Vector{Float32}
    @test isequal(I, Float32[NaN, 3, NaN])

    @test isnan(mask_invalid(Float32[-1.0f31], ValidityChecks(Float32, -1.0e31, nothing, nothing))[1])

    R = reshape(Float64.(1:24), 2, 3, 4)
    record = ValidityChecks(Float64, nothing, nothing, 1:6)
    @test isnan.(mask_invalid(R, record, 1:2)) == cat(falses(2, 3), trues(2, 3, 3); dims = 3)
    @test_throws DimensionMismatch mask_invalid(R, record)
    @test isnan.(mask_invalid(R, ValidityChecks(Float64, nothing, nothing, [1, 100])))[:, :, 1] == Bool[0 1 1; 0 0 0]
    P = rand(Float32, 3, 100)
    P[2, 7] = 0.35  # a fill within the bounds of some components only
    tiles = ValidityChecks(Float32, P[2, 7], [0.2, 0.3, 0.4], 0.9)
    @test isnan(mask_invalid(P, tiles)[2, 7])
    @test isequal(mask_invalid(P, tiles), permutedims(mask_invalid(permutedims(P), tiles, 2)))

    c = ValidityChecks(Float64, -1, [0, 1, 2], nothing)
    @test c[2].validmin == [1.0]
    @test c[2].fillval == [-1.0]
    @test isequal(ValidityChecks(Float32, nothing, nothing, nothing), ValidityChecks(Float32, nothing, nothing, nothing))
    @test hash(ValidityChecks(Float32, -1, 0, 1)) == hash(ValidityChecks(Float32, -1, 0, 1))
    @test Base.return_types(ValidityChecks, (Type{Float32}, Any, Any, Any)) == [ValidityChecks{Float32}]

    overlapping = Float32.(1:1025)
    mask_invalid!(view(overlapping, 2:1025), view(overlapping, 1:1024))
    @test overlapping[2:end] == Float32.(1:1024)
    @test_throws DimensionMismatch mask_invalid!(zeros(2, 3), zeros(3, 2))

    t = [DateTime(2000)]
    @test mask_invalid(t) === t
end
