"""
A variable `v` of a type derived from `AbstractDataVariable` should at least implement:

* `Base.parent(v)`: the parent array of the variable

Optional:

* `tdimnum(v)`: the index of the time dimension (`timedim`, `times` derive from it)
* `units(v)`: the units of the variable
* `getmeta(v)`: the metadata of the variable
* `name(v)`: the name of the variable
* `dims(v, i)`: the `i`-th dimension of the variable
* `dims(v, name)`: the dimension named `name` of the variable
"""
abstract type AbstractDataVariable{T, N} <: AbstractArray{T, N} end

# https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-array
Base.parent(var::AbstractDataVariable) = var.data
dims(var::AbstractDataVariable, i::Integer) = hasfield(typeof(var), :dims) ? getfield(var, :dims)[i] : axes(var, i)
Base.iterate(A::AbstractDataVariable, args...) = iterate(parent(A), args...)
for f in (:size, :Array)
    @eval Base.$f(var::AbstractDataVariable) = $f(parent(var))
end

@propagate_inbounds Base.getindex(var::AbstractDataVariable, I::Vararg{Int}) = getindex(parent(var), I...)
Base.getindex(var::AbstractDataVariable, s::Union{String, Symbol}) = getindex(getmeta(var), s)

@propagate_inbounds Base.setindex!(var::AbstractDataVariable, v, I::Vararg{Int}) = setindex!(parent(var), v, I...)
Base.setindex!(var::AbstractDataVariable, v, s::Union{String, Symbol}) = setindex!(getmeta(var), v, s)

Base.get(var::AbstractDataVariable, s::Union{String, Symbol}, d = nothing) = _get(getmeta(var), s, d)
Base.get(f::Function, var::AbstractDataVariable, s::Union{String, Symbol}) = get(f, getmeta(var), s)

_timerange_str(times) = "Time Range: $(minimum(times)) to $(maximum(times))"

function Base.show(io::IO, var::T) where {T <: AbstractDataVariable}
    print_name(io, var)
    print(io, " [")
    time = hastimedim(var) ? times(var) : nothing
    isnothing(time) || isempty(time) || print(io, _timerange_str(time), ",")
    u = units(var)
    isnothing(u) || print(io, " Units: ", u, ",")
    print(io, " Size: ", size(var))
    print(io, "]")
    return
end

_is_valid(::Nothing) = false
_is_valid(x) = applicable(isempty, x) ? !isempty(x) : true

# Add Base.show methods for pretty printing
function Base.show(io::IO, m::MIME"text/plain", var::T) where {T <: AbstractDataVariable}
    print(io, "$T: ")
    print_name(io, var)
    println(io)
    time = hastimedim(var) ? times(var) : nothing
    isnothing(time) || isempty(time) || println(io, "  ", _timerange_str(time))
    u = units(var)
    isnothing(u) || println(io, "  Units: ", u)
    println(io, "  Size: ", size(var))
    println(io, "  Memory Usage: ", Base.format_bytes(Base.summarysize(var)))
    if (m = getmeta(var)) |> _is_valid
        print(io, "  Metadata:")
        _println_value(io, m)
    end
    return
end

"""
    DataVariable(data, dims, tdim, metadata; name = metadata["name"])
    DataVariable(data, metadata = Dict(); name = metadata["name"])

In-memory variable: `data` with dimensions `dims` (one per axis), time dimension index `tdim` (or `nothing`),
`metadata` and `name` (`""` when `metadata` has none). Without `dims`, the dimensions are the axes of `data`
and there is no time dimension.
Each dimension is a vector along its axis or, when time-varying (e.g. energy bins), a matrix along its
axis and the time axis in the variable's order (as CDF `DEPEND_i`); others throw a `DimensionMismatch`.
"""
struct DataVariable{T, N, A <: AbstractArray{T, N}, D <: Tuple, M} <: AbstractDataVariable{T, N}
    data::A
    dims::D
    tdim::Union{Int, Nothing}
    name::String
    metadata::M
    function DataVariable(data::A, dims::D, tdim, metadata::M; name = getmeta(metadata, "name", "")) where {T, N, A <: AbstractArray{T, N}, D <: Tuple, M}
        _checkfits(data, dims, tdim)
        return new{T, N, A, D, M}(data, dims, tdim, string(name), metadata)
    end
end

DataVariable(data, metadata = Dict(); name = getmeta(metadata, "name", "")) = DataVariable(data, axes(data), nothing, metadata; name)

Base.IndexStyle(::Type{<:DataVariable{T, N, A}}) where {T, N, A} = IndexStyle(A)

tdimnum(v::DataVariable) = v.tdim

Base.similar(A::AbstractDataVariable, ::Type{T}, sz::Dims) where {T} = _wrap(A, similar(parent(A), T, sz))

# `data` derived from `A`: same-size data (e.g. broadcasting, `copy`) keeps the dimensions.
_wrap(A, data::AbstractArray) = size(data) == size(A) ? rebuild(A, data) : DataVariable(data, _derivedmeta(A); name = name(A))
_wrap(A, x) = x

Base.getindex(var::AbstractDataVariable, I...) = _index(getindex, var, I)
Base.view(var::AbstractDataVariable, I...) = _index(view, var, I)

# Non-scalar indexing slices each dimension along the axes it spans, with `f` as the data.
function _index(f, var, I)
    data = f(parent(var), I...)
    data isa AbstractArray || return data
    J, N = to_indices(var, I), ndims(var)
    # Fewer indices than dimensions index linearly
    length(J) >= N && all(j -> j isa Integer, J[(N + 1):end]) || return data
    ds, kept = _checkeddims(var), _kept(J, Val(1))
    # Slices of fitting dimensions fit, so skip `rebuild`'s fallback to axes (a union per dimension).
    # A time-varying dimension's slice type depends on the time index's type, hence a static `tdim`.
    return _static(tdimnum(var), Val(N)) do t
        DataVariable(data, map(n -> _slicedim(f, ds[_valof(n)], n, t, J), kept), _newtdim(kept, t), _indexmeta(f, var); name = name(var))
    end
end

# A view is the variable itself, so writes to its metadata reach `var`.
_indexmeta(::typeof(view), var) = getmeta(var)
_indexmeta(f, var) = _derivedmeta(var)

# `g(Val(t))` for `t` in `1:n`, else `g(nothing)`: one branch per value.
_static(g, ::Nothing, ::Val) = g(nothing)
_static(g, t::Integer, ::Val{0}) = throw(ArgumentError("time dimension $t out of range"))
_static(g, t::Integer, ::Val{n}) where {n} = t == n ? g(Val(n)) : _static(g, t, Val(n - 1))

_newtdim(kept, ::Nothing) = nothing
_newtdim(kept, t::Val) = findfirst(==(t), kept)

# `Val` positions of the non-scalar indices, from their types so the result is inferable.
_kept(::Tuple{}, ::Val) = ()
_kept(I::Tuple, ::Val{k}) where {k} = (rest = _kept(Base.tail(I), Val(k + 1)); first(I) isa Integer ? rest : (Val(k), rest...))

_slicedim(f, d::AbstractVector, ::Val{k}, t, I) where {k} = f(d, I[k])
# Indexed by its own axis alone, a matrix would slice linearly.
_slicedim(f, d::AbstractMatrix, ::Val{k}, ::Val{t}, I) where {k, t} = k < t ? f(d, I[k], I[t]) : f(d, I[t], I[k])

# Broadcast
# Reference: https://docs.julialang.org/en/v1/manual/interfaces/#man-interfaces-broadcasting
# Reference: https://github.com/rafaqz/DimensionalData.jl/blob/main/src/array/broadcast.jl
using Base.Broadcast: ArrayStyle, Broadcasted
Base.BroadcastStyle(::Type{<:AbstractDataVariable}) = ArrayStyle{AbstractDataVariable}()

# Broadcasts over the parents, so the result is what they give (e.g. a scalar for 0-dim, a range for
# ranges), then wraps it; a loop into a `similar` destination would run over a union of types.
Base.copy(bc::Broadcasted{ArrayStyle{AbstractDataVariable}}) = _wrap(find_datavariable(bc), Broadcast.materialize(_parents(bc)))
_parents(bc::Broadcasted) = Broadcast.broadcasted(bc.f, map(_parents, bc.args)...)
_parents(x::AbstractDataVariable) = parent(x)
_parents(x) = x

find_datavariable(x::Broadcasted) = find_datavariable(x.args)
function find_datavariable(x::Tuple)
    found = find_datavariable(x[1])
    return isnothing(found) ? find_datavariable(Base.tail(x)) : found
end
find_datavariable(::Tuple{}) = nothing
find_datavariable(x::AbstractDataVariable) = x
find_datavariable(::Any) = nothing
