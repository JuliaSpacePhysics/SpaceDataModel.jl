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

# Allow merging NoMetadata with a Dict or keyword arguments
Base.merge(::NoMetadata, d::AbstractDict) = copy(d)
Base.merge(::NoMetadata, p::Base.Pairs) = Dict{Any,Any}(p)
Base.merge(m::NoMetadata, d, rest...) = merge(merge(m, d), rest...)

Base.haskey(::NoMetadata, args...) = false
Base.get(::NoMetadata, key, default=nothing) = default
Base.length(::NoMetadata) = 0
for f in (:NamedTuple, :Dict)
    @eval Base.$f(::NoMetadata) = $f()
    @eval Base.convert(::Type{$f}, ::NoMetadata) = $f()
end