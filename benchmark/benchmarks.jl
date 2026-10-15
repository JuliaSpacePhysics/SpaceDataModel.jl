using BenchmarkTools
using SpaceDataModel: DataVariable, mask_invalid!, ValidityChecks

const SUITE = BenchmarkGroup()

SUITE["mask"] = let g = BenchmarkGroup(), A = rand(Float32, 3, 10^5), B = similar(A)
    lo, hi = Float32[0, 0.1, 0.2], Float32[0.9, 0.95, 1]
    g["one value per check"] = @benchmarkable mask_invalid!($B, $A, $(ValidityChecks(Float32, -1.0f31, 0.1, 0.9)))
    g["per component"] = @benchmarkable mask_invalid!($B, $A, $(ValidityChecks(Float32, -1.0f31, lo, hi)))
    g["fill in range"] = @benchmarkable mask_invalid!($B, $A, $(ValidityChecks(Float32, 0.5, lo, hi)))
    g
end

# A time-varying (matrix) dimension is what can make results type-unstable.
SUITE["DataVariable"] = let g = BenchmarkGroup(), A = rand(Float32, 3, 10^5)
    v = DataVariable(A, (rand(3, 10^5), collect(1.0:10^5)), 2, Dict())
    g["broadcast"] = @benchmarkable $v .* 2
    g["broadcast parent"] = @benchmarkable $A .* 2
    g["map"] = @benchmarkable map(abs, $v)
    g["map parent"] = @benchmarkable map(abs, $A)
    g
end
