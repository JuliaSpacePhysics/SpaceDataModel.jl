# https://github.com/rafaqz/DimensionalData.jl/blob/main/src/Lookups/metadata.jl

"""
    NoMetadata

Indicates an object has no metadata. But unlike using `nothing`, 
`get`, `keys` and `haskey` will still work on it, `get` always
returning the fallback argument. `keys` returns `()` while `haskey`
always returns `false`.
"""
struct NoMetadata end

Base.keys(::NoMetadata) = ()
Base.haskey(::NoMetadata, args...) = false
Base.get(::NoMetadata, key, default=nothing) = default
Base.length(::NoMetadata) = 0