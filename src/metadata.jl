# https://github.com/rafaqz/DimensionalData.jl/blob/main/src/Lookups/metadata.jl

"""
    NoMetadata()

Empty, immutable metadata.
"""
struct NoMetadata end

Base.keys(::NoMetadata) = ()
Base.values(::NoMetadata) = ()
Base.length(::NoMetadata) = 0
Base.iterate(::NoMetadata) = nothing

# Values widen to `Any` so a later `setindex!` is not bound
Base.merge(::NoMetadata, d) = isempty(d) ? NoMetadata() : (p = pairs(d); Dict{keytype(p), Any}(p))
Base.merge(d::AbstractDict, ::NoMetadata) = copy(d)
Base.merge(nm::NoMetadata, d, rest...) = merge(merge(nm, d), rest...)

Base.haskey(::NoMetadata, key) = false
Base.getindex(::NoMetadata, key) = throw(KeyError(key))
Base.get(::NoMetadata, key, default = nothing) = default
Base.get(f::Base.Callable, ::NoMetadata, key) = f()

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

# Through the three-argument `get` alone as AbstractDicts need not define `get(f, d, key)`
struct NoKey end

function Base.getindex(d::OverlayDict, key)
    v = get(d.overlay, key, NoKey())
    return v isa NoKey ? d.base[key] : v
end

function Base.get(d::OverlayDict, key, default)
    v = get(d.overlay, key, NoKey())
    return v isa NoKey ? get(d.base, key, default) : v
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
