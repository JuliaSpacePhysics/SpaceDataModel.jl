hastimedim(x) = !isnothing(tdimnum(x))

# Not `resolve_dim(x, nothing)`, which defaults a plain vector to its only axis.
timedim(x) = dims(x, @something tdimnum(x) throw(ArgumentError("$(typeof(x)) has no time dimension")))

unwrap(v::AbstractDataVariable) = parent(v)
@inline axiskeys(v::AbstractDataVariable, d::Integer) = unwrap(dims(v, d))
dimnum(v::AbstractDataVariable, s::Union{String, Symbol}) =
    @something _dimnum(v, s) throw(ArgumentError("dimension $s not found"))

# Other variable types wrap a specific source, so a rebuilt variable is a `DataVariable` with the
# metadata of `v`; types that can hold new data may add `rebuild` methods returning their own type.
rebuild(v::AbstractDataVariable, data) = rebuild(DataVariable(v), data)
rebuild(v::AbstractDataVariable, data, newdims::Tuple) = rebuild(DataVariable(v), data, newdims)
rekey(v::AbstractDataVariable, d::Integer, keys) = rekey(DataVariable(v), d, keys)

rebuild(v::DataVariable{T, N, D}, data) where {T, N, D} = DataVariable{D}(data, v.time, v.dims, v.coords, name(v), _derivedmeta(v))

# Same samples along `d`, relabelled: other coordinates stay. Inlined so a constant `d` picks the branch,
# whose times differ in type.
@inline rekey(v::DataVariable{T, N, D}, d::Integer, keys) where {T, N, D} = !isnothing(D) && d == D ?
    DataVariable{D}(parent(v), keys, v.dims, v.coords, name(v), _derivedmeta(v)) : _rekey(v, d, keys)
function _rekey(v::DataVariable{T, N, D}, d, keys) where {T, N, D}
    ds = copy(v.dims)
    ds[d] = _dimcoord(parent(v), keys, d, D)
    return DataVariable{D}(parent(v), v.time, ds, v.coords, name(v), _derivedmeta(v))
end

# A kept axis `Val(i)` keeps its coordinates. A coordinate along an axis that is dropped or takes new samples
# collapses when constant along it (e.g. energies after averaging over time), else is dropped.
function rebuild(v::DataVariable{T, N, D}, data, newdims::Tuple) where {T, N, D}
    newpos = zeros(Int, N)
    for (j, n) in enumerate(newdims)
        n isa Val && (newpos[_valof(n)] = j)
    end
    g = c -> _movecoord(c, newpos)
    t = _newtdim(newdims, Val(D))
    ds = Union{Nothing, Coord}[
        j === t ? nothing : n isa Val ? g(v.dims[_valof(n)]) : _dimcoord(data, _named(first(n), last(n)), j, t)
            for (j, n) in enumerate(newdims)
    ]
    time = isnothing(t) ? nothing : _keysof(v, newdims[t])
    return DataVariable{t}(data, time, ds, _movedcoords(g, v, i -> newpos[i] == 0), name(v), _derivedmeta(v))
end
_keysof(v, ::Val) = v.time
_keysof(_, d::Pair) = last(d)
_named(::Symbol, ::Nothing) = nothing
_named(n::Symbol, keys) = DataVariable(keys; name = String(n))
_named(n, keys) = keys

_valof(::Val{i}) where {i} = i
_valof(::Nothing) = nothing

_movecoord(::Nothing, newpos) = nothing
_movecoord((axs, data)::Coord, newpos) = _movecoord(axs, data, newpos)
function _movecoord(caxs, data, newpos)
    axs = Int[]
    for j in reverse(eachindex(caxs))
        a = newpos[caxs[j]]
        if a == 0
            # Collapses to its first sample, so an empty axis has none to keep.
            size(data, j) > 0 && _isconstant(data, j) || return nothing
            data = data[ntuple(i -> i == j ? 1 : Colon(), ndims(data))...]
        else
            pushfirst!(axs, a)
        end
    end
    return isempty(axs) ? nothing : _coord(Tuple(axs), data)
end
# `isequal`, so fill values (NaN) along it count as constant.
_isconstant(A, j) = (s = selectdim(A, j, 1); all(k -> isequal(selectdim(A, j, k), s), 2:size(A, j)))

# Derived variables read the metadata of `v` but write their own layer, so `r["units"] = ...` leaves `v` alone.
_derivedmeta(v) = _overlay(getmeta(v))
_overlay(m::OverlayDict) = OverlayDict(m.base, Dict{keytype(m.overlay), Any}(m.overlay))
_overlay(m::AbstractDict) = OverlayDict(m, Dict{keytype(m), Any}())
_overlay(m) = m
