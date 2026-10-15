hastimedim(x) = !isnothing(tdimnum(x))

# Not `resolve_dim(x, nothing)`, which defaults a plain vector to its only axis.
timedim(x) = dims(x, @something tdimnum(x) throw(ArgumentError("$(typeof(x)) has no time dimension")))

unwrap(v::AbstractDataVariable) = parent(v)
axiskeys(v::AbstractDataVariable, d::Integer) = unwrap(dims(v, d))
dimnum(v::AbstractDataVariable, s::Union{String, Symbol}) =
    @something _dimnum(v, s) throw(ArgumentError("dimension $s not found"))

# Most variable types wrap a specific source, so a rebuilt variable is a `DataVariable` with the
# metadata of `v`; types that can hold new data may add `rebuild` methods returning their own type.
rebuild(v::AbstractDataVariable, data) = DataVariable(data, _fitteddims(v), tdimnum(v), _derivedmeta(v); name = name(v))
rebuild(v::AbstractDataVariable, data, d::Integer, keys) =
    _rebuild(v, data, Base.setindex(dims(v), keys, d), tdimnum(v))
# Kept axes whose keys are unchanged keep their dimension objects (names, units).
function rebuild(v::AbstractDataVariable, data, newdims::Tuple, keys::Tuple)
    ds = map((n, k) -> n isa Val ? _keepdim(dims(v, _valof(n)), k) : k, newdims, keys)
    t = tdimnum(v)
    return _rebuild(v, data, ds, isnothing(t) ? nothing : findfirst(map(n -> n isa Val && _valof(n) == t, newdims)))
end
_keepdim(d, k) = k === unwrap(d) ? d : k
_keepdim(::T, k::T) where {T} = k # same type: `k` is `d` itself or new keys
rekey(v::AbstractDataVariable, d, keys) = rebuild(v, parent(v), d, keys)

_valof(::Val{i}) where {i} = i

# New keys along time cannot say what a time-varying dimension becomes (interpolated? averaged?),
# so a dimension that no longer fits becomes the plain axis. Vectors follow their axis by construction.
_rebuild(v, data, ds, t) = DataVariable(data, map((k, d) -> _followdim(data, t, k, d), ntuple(identity, length(ds)), ds), t, _derivedmeta(v); name = name(v))
_followdim(A, t, k, d::AbstractVector) = d
_followdim(A, t, k, d) = _fitsdim(A, t, k, d) ? d : axes(A, k)

# Dimensions of `v` that fit it.
_fitteddims(v) = map((k, d) -> _followdim(v, tdimnum(v), k, d), ntuple(identity, ndims(v)), dims(v))
_fitteddims(v::DataVariable) = dims(v)

_fits(A, ds, t) = length(ds) == ndims(A) && (isnothing(t) || 1 <= t <= ndims(A)) && all(map((k, d) -> _fitsdim(A, t, k, d), ntuple(identity, length(ds)), ds))

# Layouts: see `DataVariable`.
_fitsdim(A, t, k, d::AbstractVector) = length(d) == size(A, k)
_fitsdim(A, t, k, d::AbstractMatrix) = !isnothing(t) && t != k && size(d) == (size(A, min(k, t)), size(A, max(k, t)))
_fitsdim(A, t, k, d) = false

# Derived variables read the metadata of `v` but write their own layer, so `r["units"] = ...` leaves `v` alone.
_derivedmeta(v) = _overlay(getmeta(v))
_overlay(m::OverlayDict) = OverlayDict(m.base, copy(m.overlay))
_overlay(m::AbstractDict) = OverlayDict(m, Dict{keytype(m), valtype(m)}())
_overlay(m) = m
