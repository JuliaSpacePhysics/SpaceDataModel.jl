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

# Allow merging NoMetadata with a Dict or keyword arguments
function Base.merge(::NoMetadata, d, rest...)
    res = merge(d, rest...)
    isempty(res) ? NoMetadata() : res # for cases where no kwarg is provided
end

Base.haskey(::NoMetadata, args...) = false
Base.get(::NoMetadata, key, default=nothing) = default
Base.length(::NoMetadata) = 0