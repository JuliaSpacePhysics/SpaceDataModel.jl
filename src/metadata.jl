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
Base.values(::NoMetadata) = ()
Base.iterate(::NoMetadata) = nothing

# Allow merging NoMetadata with a Dict or keyword arguments
Base.merge(::NoMetadata, d) = isempty(d) ? NoMetadata() : copy(d)
Base.merge(d::AbstractDict, ::NoMetadata) = copy(d)
Base.merge(::NoMetadata, d, rest...) = merge(d, rest...)

Base.haskey(::NoMetadata, args...) = false
Base.get(::NoMetadata, key, default = nothing) = default

"""
    OverlayDict(base, overlay)
    OverlayDict{K, V}(base)

Dictionary view where `overlay` entries shadow `base`; writes update only `overlay`.
"""
struct OverlayDict{K, V, B, O} <: AbstractDict{K, V}
    base::B
    overlay::O
end

OverlayDict{K, V}(base) where {K, V} = OverlayDict(base, Dict{K, V}())
OverlayDict(base::B, overlay::O) where {B, O} =
    OverlayDict{Union{keytype(base), keytype(overlay)}, Union{valtype(base), valtype(overlay)}, B, O}(base, overlay)

function Base.getindex(d::OverlayDict, key)
    return get(d.overlay, key) do
        d.base[key]
    end
end

function Base.get(d::OverlayDict, key, default)
    return get(d.overlay, key) do
        get(d.base, key, default)
    end
end

Base.setindex!(d::OverlayDict, value, key) = setindex!(d.overlay, value, key)
Base.haskey(d::OverlayDict, key) = haskey(d.overlay, key) || haskey(d.base, key)
Base.length(d::OverlayDict) =
    length(d.overlay) + count(kv -> !haskey(d.overlay, first(kv)), d.base)

function Base.iterate(d::OverlayDict, state = (1, nothing))
    phase, st = state
    if phase == 1
        next = isnothing(st) ? iterate(d.overlay) : iterate(d.overlay, st)
        if next !== nothing
            kv, st2 = next
            return (kv, (1, st2))
        end
        st = nothing
        phase = 2
    end
    while true
        next = isnothing(st) ? iterate(d.base) : iterate(d.base, st)
        isnothing(next) && break
        kv, st = next
        haskey(d.overlay, kv.first) && continue
        return (kv, (2, st))
    end
    return nothing
end
