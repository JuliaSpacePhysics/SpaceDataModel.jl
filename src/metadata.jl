# https://github.com/rafaqz/DimensionalData.jl/blob/main/src/Lookups/metadata.jl

"""
    NoMetadata

Indicates an object has no metadata. But unlike using `nothing`, 
`get`, `keys` and `haskey` will still work on it, `get` always
returning the fallback argument. `keys` returns `()` while `haskey`
always returns `false`.
"""
struct NoMetadata end

const NoData = NoMetadata

Base.keys(::NoMetadata) = ()
Base.values(::NoMetadata) = ()
Base.iterate(::NoMetadata) = nothing

Base.merge(::NoMetadata, d) = isempty(d) ? NoMetadata() : copy(d)

# Allow merging NoMetadata with a Dict or keyword arguments
Base.merge(::NoMetadata, d, rest...) = merge(d, rest...)

Base.haskey(::NoMetadata, args...) = false
Base.get(::NoMetadata, key, default=nothing) = default
Base.length(::NoMetadata) = 0