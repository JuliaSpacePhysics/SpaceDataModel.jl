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
    DataVariable(data, dims, tdim, metadata)
    DataVariable(data, metadata = Dict())

In-memory variable: `data` with dimensions `dims` (one per axis), time dimension index `tdim` (or `nothing`)
and `metadata`. Without `dims`, the dimensions are the axes of `data` and there is no time dimension.
Each dimension is a vector along its axis or, when time-varying (e.g. energy bins), a matrix along its
axis and the time axis in the variable's order (as CDF `DEPEND_i`); others throw a `DimensionMismatch`.
"""
struct DataVariable{T, N, A <: AbstractArray{T, N}, D <: Tuple, M} <: AbstractDataVariable{T, N}
    data::A
    dims::D
    tdim::Union{Int, Nothing}
    metadata::M
    function DataVariable(data::A, dims::D, tdim, metadata::M) where {T, N, A <: AbstractArray{T, N}, D <: Tuple, M}
        _fits(data, dims, tdim) || throw(DimensionMismatch("dimensions $(map(summary, dims)) with time dimension $tdim do not fit data of size $(size(data))"))
        return new{T, N, A, D, M}(data, dims, tdim, metadata)
    end
end

DataVariable(data, metadata = Dict()) = DataVariable(data, axes(data), nothing, metadata)

Base.IndexStyle(::Type{<:DataVariable{T, N, A}}) where {T, N, A} = IndexStyle(A)

tdimnum(v::DataVariable) = v.tdim

# Same-size results (e.g. broadcasting, `copy`) keep the dimensions.
Base.similar(A::AbstractDataVariable, ::Type{T}, sz::Dims) where {T} = sz == size(A) ?
    rebuild(A, similar(parent(A), T, sz)) :
    DataVariable(similar(parent(A), T, sz), _derivedmeta(A))

Base.getindex(var::AbstractDataVariable, I...) = _index(getindex, var, I)
Base.view(var::AbstractDataVariable, I...) = _index(view, var, I)

# Non-scalar indexing slices each dimension along the axes it spans, with `f` as the data.
function _index(f, var, I)
    data = f(parent(var), I...)
    data isa AbstractArray && length(I) == ndims(var) || return data
    t, ds = tdimnum(var), dims(var)
    kept = _kept(I, Val(1))
    return rebuild(var, data, kept, map(n -> _slicedim(f, var, ds[_valof(n)], _valof(n), t, I), kept))
end

# `Val` positions of the non-scalar indices, from their types so the result is inferable.
_kept(::Tuple{}, ::Val) = ()
_kept(I::Tuple, ::Val{k}) where {k} = (rest = _kept(Base.tail(I), Val(k + 1)); first(I) isa Integer ? rest : (Val(k), rest...))

_slicedim(f, var, d::AbstractVector, k, t, I) = f(d, I[k])
# Indexed by its own axis alone, a matrix would slice linearly; one that does not fit is left to `rebuild`.
_slicedim(f, var, d::AbstractMatrix, k, t, I) = !_fitsdim(var, t, k, d) ? d : k < t ? f(d, I[k], I[t]) : f(d, I[t], I[k])
_slicedim(f, var, d, k, t, I) = d

# Broadcast
# Reference: https://docs.julialang.org/en/v1/manual/interfaces/#man-interfaces-broadcasting
# Reference: https://github.com/rafaqz/DimensionalData.jl/blob/main/src/array/broadcast.jl
using Base.Broadcast: ArrayStyle, Broadcasted
Base.BroadcastStyle(::Type{<:AbstractDataVariable}) = ArrayStyle{AbstractDataVariable}()

Base.similar(bc::Broadcasted{ArrayStyle{AbstractDataVariable}}, ::Type{T}) where {T} = similar(find_datavariable(bc), T, axes(bc))

find_datavariable(x::Broadcasted) = find_datavariable(x.args)
function find_datavariable(x::Tuple)
    found = find_datavariable(x[1])
    return isnothing(found) ? find_datavariable(Base.tail(x)) : found
end
find_datavariable(::Tuple{}) = nothing
find_datavariable(x::AbstractDataVariable) = x
find_datavariable(::Any) = nothing
