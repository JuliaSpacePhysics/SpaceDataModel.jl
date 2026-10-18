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
* `coords(v)`: further coordinates, `axes => values` (e.g. labels of a dimension)
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

_label(x) = (n = name(x); isempty(n) ? summary(x) : n)

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
    cs = coords(var)
    isempty(cs) || println(io, "  Coordinates: ", join(map(((axs, c),) -> string(_label(c), " ", axs), cs), ", "))
    println(io, "  Memory Usage: ", Base.format_bytes(Base.summarysize(var)))
    if (m = getmeta(var)) |> _is_valid
        print(io, "  Metadata:")
        _println_value(io, m)
    end
    return
end

# A coordinate `axes => data`: axis `j` of `data` runs along axis `axes[j]` of the variable.
const Coord = Pair{Tuple{Vararg{Int}}, AbstractArray}

# From user input: an `Integer` is one axis; other axis orders permute `data` lazily.
_coord((axs, data)::Pair) = _coord(axs isa Integer ? (Int(axs),) : axs, data)
function _coord(axs::NTuple{K, Int}, data::AbstractArray) where {K}
    ndims(data) == K || throw(DimensionMismatch("$(ndims(data))-dimensional coordinate along axes $axs"))
    allunique(axs) || throw(ArgumentError("coordinate axes $axs repeat"))
    issorted(axs) && return Coord(axs, data)
    p = sortperm(collect(axs))
    return Coord(ntuple(j -> axs[p[j]], Val(K)), PermutedDimsArray(data, p))
end

"""
    DataVariable(data; time = nothing, dims = (), coords = (), metadata = Dict(), name = metadata["name"])
    DataVariable(v::AbstractDataVariable)

In-memory variable: `data` with times `time` (`d => t` along axis `d`, or `t` for a vector), coordinates `dims`
of its other axes (`i => c`; axes left out are plain `Base.axes(data, i)`), further coordinates `coords`
(`axes => c`, e.g. `2 => labels` or `(1, 3) => bins`) that indexing slices along with the data.

A coordinate in `dims` is a vector along its axis or, when time-varying (e.g. energy bins),
a matrix along its axis and the time axis in the variable's order (as CDF `DEPEND_i`).
Integer-indexing its axis keeps it along time; dropping or resampling the time axis keeps it only if constant.
"""
struct DataVariable{T, N, D, A <: AbstractArray{T, N}, Tm, M} <: AbstractDataVariable{T, N}
    data::A
    time::Tm                            # keys of the time axis `D`; `nothing` without one
    dims::Vector{Union{Nothing, Coord}} # each axis's coordinate, `nothing` for the plain axis (and for the time axis)
    coords::Vector{Coord}               # these vectors are shared by derived variables, so never mutated
    name::String
    metadata::M
    function DataVariable{D}(data::A, time::Tm, dims::Vector{Union{Nothing, Coord}}, coords::Vector{Coord}, name, metadata::M) where {D, T, N, A <: AbstractArray{T, N}, Tm, M}
        _checkcoords(data, Val(D), time, dims, coords)
        return new{T, N, D, A, Tm, M}(data, time, dims, coords, string(name), metadata)
    end
end

function _checkcoords(data, ::Val{D}, time, dims, coords) where {D}
    length(dims) == ndims(data) || throw(DimensionMismatch("$(length(dims)) dimensions for data of size $(size(data))"))
    if isnothing(D)
        isnothing(time) || throw(ArgumentError("times without a time dimension"))
    else
        1 <= D <= ndims(data) || throw(ArgumentError("time dimension $D out of 1:$(ndims(data))"))
        time isa AbstractVector && length(time) == size(data, D) ||
            throw(DimensionMismatch("times $(summary(time)) do not fit axis $D of data of size $(size(data))"))
    end
    foreach(c -> _checkfits(data, c), coords)
    for (i, c) in enumerate(dims)
        isnothing(c) && continue
        _checkfits(data, c)
        axs = first(c)
        i !== D && (axs == (i,) || !isnothing(D) && axs == minmax(i, D)) ||
            throw(DimensionMismatch("coordinate of dimension $i is along axes $axs, not along it or along it and time $D"))
    end
    return
end
_checkfits(data, (axs, c)::Coord) = all(a -> 1 <= a <= ndims(data), axs) && size(c) == map(a -> size(data, a), axs) ||
    throw(DimensionMismatch("coordinate $(summary(c)) along axes $axs does not fit data of size $(size(data))"))

# Inlined so a literal time axis reaches `_static` as a constant.
@inline DataVariable(data::AbstractArray; time = nothing, dims = (), coords = (), metadata = Dict(), name = getmeta(metadata, "name", "")) =
    _static(t -> _datavariable(data, t, _times(time), dims, coords, metadata, name), _tdim(data, time), Val(ndims(data)))

function _datavariable(data, t, time, dims, coords, metadata, name)
    D = _valof(t)
    allunique(map(first, dims)) || throw(ArgumentError("dimensions $(map(first, dims)) repeat"))
    ds = Vector{Union{Nothing, Coord}}(nothing, ndims(data))
    for (i, c) in dims
        1 <= i <= ndims(data) && i !== D || throw(ArgumentError("dimension $i is the time axis or out of 1:$(ndims(data))"))
        ds[i] = _dimcoord(data, c, i, D)
    end
    return DataVariable{D}(data, time, ds, Coord[_coord(c) for c in coords], name, metadata)
end
_tdim(_, ::Nothing) = nothing
_tdim(::AbstractVector, ::AbstractVector) = Val(1)
_tdim(_, ::AbstractVector) = throw(ArgumentError("times of a multidimensional variable need their axis: `time = d => t`"))
_tdim(_, (d, _)::Pair) = d
_times(t) = t
_times((_, t)::Pair) = t

DataVariable(v::DataVariable) = v
function DataVariable(v::AbstractDataVariable)
    t = tdimnum(v)
    return DataVariable(
        parent(v); time = isnothing(t) ? nothing : t => dims(v, t), dims = [i => dims(v, i) for i in 1:ndims(v) if i != t],
        coords = coords(v), metadata = getmeta(v), name = name(v)
    )
end

# The coordinate `d` of axis `i` with time axis `t`, `nothing` for the plain axis. Equal keys (`1:3`) are a coordinate.
_dimcoord(data, d::AbstractVector, i, t) = d === axes(data, i) ? nothing : Coord((i,), d)
_dimcoord(data, d::AbstractMatrix, i, t) =
    isnothing(t) || t == i ? throw(DimensionMismatch("matrix dimension $i without another time dimension")) : Coord(minmax(i, t), d)
_dimcoord(data, d, i, t) = throw(DimensionMismatch("dimension $i is a $(summary(d)), not a vector or time-varying matrix"))

Base.IndexStyle(::Type{<:DataVariable{T, N, D, A}}) where {T, N, D, A} = IndexStyle(A)

tdimnum(::DataVariable{T, N, D}) where {T, N, D} = D
@inline dims(v::DataVariable{T, N, D}, i::Integer) where {T, N, D} = !isnothing(D) && i == D ? v.time : _dim(v, i)
_dim(v::DataVariable, i) = (c = v.dims[i]; isnothing(c) ? axes(v.data, i) : last(c))
coords(v::DataVariable) = v.coords

# Same shape as `A`, so the result type does not depend on a size check.
Base.similar(A::AbstractDataVariable, ::Type{T}) where {T} = rebuild(A, similar(parent(A), T))
Base.map(f, A::AbstractDataVariable) = rebuild(A, map(f, parent(A)))

function Base.similar(A::AbstractDataVariable, ::Type{T}, sz::Dims) where {T}
    data = similar(parent(A), T, sz)
    return size(data) == size(A) ? rebuild(A, data) : DataVariable(data; metadata = _derivedmeta(A), name = name(A))
end

Base.getindex(var::AbstractDataVariable, I...) = _index(getindex, var, I)
Base.view(var::AbstractDataVariable, I...) = _index(view, var, I)

function _index(f, var, I)
    data = f(parent(var), I...)
    data isa AbstractArray || return data
    J = to_indices(var, I)
    N = ndims(var)
    # Fewer indices than dimensions index linearly
    length(J) >= N && all(j -> j isa Integer, J[(N + 1):end]) || return data
    return _slicevar(f, DataVariable(var), data, J)
end
# Non-scalar indexing slices each coordinate along the axes it spans, with `f` as the data; a coordinate
# whose axes are all indexed by integers is dropped.
function _slicevar(f::F, var::DataVariable{T, N, D}, data, J) where {F, T, N, D}
    kept = _kept(J)
    g = c -> _slice(f, c, J)
    ds = Union{Nothing, Coord}[g(var.dims[_valof(n)]) for n in kept]
    cs = _movedcoords(g, var, i -> J[i] isa Integer)
    return DataVariable{_newtdim(kept, Val(D))}(data, _slicetime(f, var.time, J, Val(D)), ds, cs, name(var), _indexmeta(f, var))
end

# The coordinates `g` keeps (non-`nothing`) of `v`'s further coordinates and of its `dropped` axes,
# e.g. time-varying energies of a selected channel, which run along time.
function _movedcoords(g, v, dropped)
    cs = Coord[]
    for c in v.coords
        _pushsome!(cs, g(c))
    end
    for (i, c) in enumerate(v.dims)
        dropped(i) && _pushsome!(cs, g(c))
    end
    return cs
end
_pushsome!(cs, c) = isnothing(c) ? cs : push!(cs, c)

# Unpacked into a call, so it specializes on the coordinate's own types.
_slice(f, ::Nothing, J) = nothing
_slice(f, (axs, c)::Coord, J) = _slice(f, axs, c, J)
_slice(f, axs, c, J) = all(a -> J[a] isa Integer, axs) ? nothing :
    Coord(Tuple(count(k -> !(J[k] isa Integer), 1:a) for a in axs if !(J[a] isa Integer)), f(c, map(a -> J[a], axs)...))

_slicetime(f, t, J, ::Val{nothing}) = nothing
_slicetime(f, t, J, ::Val{D}) where {D} = J[D] isa Integer ? nothing : _slicekeys(f, t, J[D])
_slicekeys(f, t, j) = f(t, j)
# Not through `getindex`/`view`: re-entering them with the converted index widens inference of the result.
_slicekeys(f, t::DataVariable{T, 1}, j) where {T} = _slicevar(f, t, f(parent(t), j), (j,))

# A view is the variable itself, so writes to its metadata reach `var`.
_indexmeta(::typeof(view), var) = getmeta(var)
_indexmeta(f, var) = _derivedmeta(var)

# `g(Val(t))` for `t` in `1:n`, else `g(nothing)`: one branch per value.
_static(g, ::Nothing, ::Val) = g(nothing)
_static(g, t::Val, ::Val) = g(t)
_static(g, t::Integer, ::Val{0}) = throw(ArgumentError("time dimension $t out of range"))
@inline _static(g, t::Integer, ::Val{n}) where {n} = t == n ? g(Val(n)) : _static(g, t, Val(n - 1))

# Position of the time axis `D` among `dims` (`Val(D)`, or `Val(D) => keys`), from their types.
@generated function _newtdim(dims::Tuple, ::Val{D}) where {D}
    isnothing(D) && return nothing
    return findfirst(T -> T <: Union{Val{D}, Pair{Val{D}}}, Tuple(dims.parameters))
end

# `Val` positions of the non-scalar indices, from their types so the result is inferable at any `ndims`.
@generated _kept(I::Tuple) = Expr(:tuple, (:(Val($k)) for (k, T) in enumerate(I.parameters) if !(T <: Integer))...)

# Broadcast
# Reference: https://docs.julialang.org/en/v1/manual/interfaces/#man-interfaces-broadcasting
# Reference: https://github.com/rafaqz/DimensionalData.jl/blob/main/src/array/broadcast.jl
using Base.Broadcast: ArrayStyle, Broadcasted
Base.BroadcastStyle(::Type{<:AbstractDataVariable}) = ArrayStyle{AbstractDataVariable}()

# Broadcasts over the parents, so the result is what they give (e.g. a scalar for 0-dim, a range for
# ranges), then wraps it; a loop into a `similar` destination would run over a union of types.
function Base.copy(bc::Broadcasted{ArrayStyle{AbstractDataVariable}})
    data = Broadcast.materialize(_parents(bc))
    return data isa AbstractArray ? _broadcasted(DataVariable(_axesvar(bc, size(data))), data) : data
end
_parents(bc::Broadcasted) = Broadcast.broadcasted(bc.f, map(_parents, bc.args)...)
_parents(x::AbstractDataVariable) = parent(x)
_parents(x) = x

# `data` extends length-1 axes of `v` and appends others; coordinates along an extended axis are dropped.
function _broadcasted(v::DataVariable{T, N, D}, data) where {T, N, D}
    size(data) == size(v) && return rebuild(v, data)
    fits((axs, _)) = all(a -> size(data, a) == size(v, a), axs)
    ds = Union{Nothing, Coord}[isnothing(c) || fits(c) ? c : nothing for c in v.dims]
    append!(ds, Iterators.repeated(nothing, ndims(data) - ndims(v)))
    return DataVariable{D}(data, v.time, ds, filter(fits, v.coords), name(v), _derivedmeta(v))
end

# The variable whose axes a result of size `sz` keeps: one it does not extend, else one whose time axis it does
# not extend (e.g. `ref .- v` with `ref` a single sample of `v`).
function _axesvar(bc, sz)
    fits(v, axs) = all(a -> sz[a] == size(v, a), axs)
    return @something(
        find_datavariable(v -> fits(v, 1:ndims(v)), bc),
        find_datavariable(v -> (D = tdimnum(v); isnothing(D) || fits(v, (D,))), bc),
        throw(DimensionMismatch("broadcasting extends the time axis of every variable; broadcast their parents instead"))
    )
end

# The first variable among the arguments of `x` for which `f` holds.
@inline find_datavariable(f, x::Broadcasted) = find_datavariable(f, x.args)
@inline function find_datavariable(f, x::Tuple)
    found = find_datavariable(f, x[1])
    return isnothing(found) ? find_datavariable(f, Base.tail(x)) : found
end
find_datavariable(f, ::Tuple{}) = nothing
find_datavariable(f, x::AbstractDataVariable) = f(x) ? x : nothing
find_datavariable(f, ::Any) = nothing
