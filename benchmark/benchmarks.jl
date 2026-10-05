using BenchmarkTools
using SpaceDataModel: mask_invalid!, ValidityChecks

const SUITE = BenchmarkGroup()

SUITE["mask"] = let g = BenchmarkGroup(), A = rand(Float32, 3, 10^5), B = similar(A)
    lo, hi = Float32[0, 0.1, 0.2], Float32[0.9, 0.95, 1]
    g["one value per check"] = @benchmarkable mask_invalid!($B, $A, $(ValidityChecks(Float32, -1.0f31, 0.1, 0.9)))
    g["per component"] = @benchmarkable mask_invalid!($B, $A, $(ValidityChecks(Float32, -1.0f31, lo, hi)))
    g["fill in range"] = @benchmarkable mask_invalid!($B, $A, $(ValidityChecks(Float32, 0.5, lo, hi)))
    g
end
