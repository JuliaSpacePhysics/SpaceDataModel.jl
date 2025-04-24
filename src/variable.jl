"""
A variable `v` of a type derived from `AbstractDataVariable` should at least implement:

* `Base.parent(v)`: the parent array of the variable

Optional:

* `times(v)`: the timestamps of the variable
* `units(v)`: the units of the variable
* `meta(v)`: the metadata of the variable
* `name(v)`: the name of the variable
"""
abstract type AbstractDataVariable{T,N} <: AbstractArray{T,N} end

# https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-array
Base.parent(var::AbstractDataVariable) = var.data
Base.iterate(A::AbstractDataVariable, args...) = iterate(parent(A), args...)
for f in (:size, :Array)
    @eval Base.$f(var::AbstractDataVariable) = $f(parent(var))
end

for f in (:getindex,)
    @eval Base.$f(var::AbstractDataVariable, I::Vararg{Int}) = $f(parent(var), I...)
end

tmin(v) = minimum(times(v))
tmax(v) = maximum(times(v))

_timerange_str(times) = "Time Range: $(minimum(times)) to $(maximum(times))"

function Base.show(io::IO, var::T) where {T<:AbstractDataVariable}
    ismissing(var) && return
    print_name(io, var)
    print(io, " [")
    time = times(var)
    isnothing(time) || print(io, _timerange_str(time), ",")
    u = units(var)
    isnothing(u) || print(io, " Units: ", u, ",")
    print(io, " Size: ", size(var))
    print(io, "]")
end

# Add Base.show methods for pretty printing
function Base.show(io::IO, m::MIME"text/plain", var::T) where {T<:AbstractDataVariable}
    ismissing(var) && return
    print(io, "$T: ")
    print_name(io, var)
    println(io)
    time = times(var)
    isnothing(time) || println(io, "  ", _timerange_str(time))
    u = units(var)
    isnothing(u) || println(io, "  Units: ", u)
    println(io, "  Size: ", size(var))
    println(io, "  Memory Usage: ", Base.format_bytes(Base.summarysize(var)))
    if (m = meta(var)) !== nothing
        println(io, "  Metadata:")
        for (key, value) in sort(collect(m), by=x -> x[1])
            println(io, "    ", key, ": ", value)
        end
    end
end