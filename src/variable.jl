"""
A variable `v` of a type derived from `AbstractDataVariable` should at least implement:

* `Base.parent(v)`: the parent array of the variable

Optional:

* `times(v)`: the timestamps of the variable
* `units(v)`: the units of the variable
* `meta(v)`: the metadata of the variable
* `name(v)`: the name of the variable
* `dim(v, i)`: the `i`-th dimension of the variable
* `dim(v, name)`: the dimension named `name` of the variable
"""
abstract type AbstractDataVariable{T, N} <: AbstractArray{T, N} end

# https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-array
Base.parent(var::AbstractDataVariable) = var.data
Base.iterate(A::AbstractDataVariable, args...) = iterate(parent(A), args...)
for f in (:size, :Array)
    @eval Base.$f(var::AbstractDataVariable) = $f(parent(var))
end

for f in (:getindex,)
    @eval @propagate_inbounds Base.$f(var::AbstractDataVariable, I::Vararg{Int}) = $f(parent(var), I...)
    @eval Base.$f(var::AbstractDataVariable, s::Union{String, Symbol}) = $f(meta(var), s)
end

@propagate_inbounds Base.setindex!(var::AbstractDataVariable, v, I::Vararg{Int}) = setindex!(parent(var), v, I...)
Base.setindex!(var::AbstractDataVariable, v, s::Union{String, Symbol}) = setindex!(meta(var), v, s)

Base.get(var::AbstractDataVariable, s::Union{String, Symbol}, d = nothing) = _get(meta(var), s, d)
Base.get(f::Function, var::AbstractDataVariable, s::Union{String, Symbol}) = get(f, meta(var), s)

_timerange_str(times) = "Time Range: $(minimum(times)) to $(maximum(times))"

function Base.show(io::IO, var::T) where {T <: AbstractDataVariable}
    ismissing(var) && return
    print_name(io, var)
    print(io, " [")
    time = times(var)
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
    ismissing(var) && return
    print(io, "$T: ")
    print_name(io, var)
    println(io)
    time = times(var)
    isnothing(time) || isempty(time) || println(io, "  ", _timerange_str(time))
    u = units(var)
    isnothing(u) || println(io, "  Units: ", u)
    println(io, "  Size: ", size(var))
    println(io, "  Memory Usage: ", Base.format_bytes(Base.summarysize(var)))
    if (m = meta(var)) |> _is_valid
        print(io, "  Metadata:")
        _println_value(io, m)
    end
    return
end

# DataVariable (a example of AbstractDataVariable)
struct DataVariable{T, N, A <: AbstractArray{T, N}, D} <: AbstractDataVariable{T, N}
    data::A
    metadata::D
end

Base.similar(A::DataVariable, ::Type{T}, dims::Dims) where {T} = DataVariable(similar(A.data, T, dims), A.metadata)

# Broadcast
# Reference: https://docs.julialang.org/en/v1/manual/interfaces/#man-interfaces-broadcasting
# Reference: https://github.com/rafaqz/DimensionalData.jl/blob/main/src/array/broadcast.jl
using Base.Broadcast: ArrayStyle, Broadcasted
Base.BroadcastStyle(::Type{<:AbstractDataVariable}) = ArrayStyle{AbstractDataVariable}()

Base.similar(bc::Broadcasted{ArrayStyle{AbstractDataVariable}}, ::Type{T}) where {T} = similar(find_datavariable(bc), T)

find_datavariable(x::Broadcasted) = find_datavariable(x.args)
function find_datavariable(x::Tuple)
    found = find_datavariable(x[1])
    return isnothing(found) ? find_datavariable(Base.tail(x)) : found
end
find_datavariable(::Tuple{}) = nothing
find_datavariable(x::AbstractDataVariable) = x
find_datavariable(::Any) = nothing
