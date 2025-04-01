abstract type AbstractDataVariable{T,N} <: AbstractArray{T,N} end

Base.size(var::AbstractDataVariable) = size(parent(var))
Base.iterate(A::AbstractDataVariable, args...) = iterate(parent(A), args...)
for f in (:getindex,)
    @eval Base.$f(var::AbstractDataVariable, I::Vararg{Int}) = $f(parent(var), I...)
end

time(v) = v.time

function Base.show(io::IO, var::T) where {T<:AbstractDataVariable}
    ismissing(var) && return
    print(io, "$T(")
    print_name(io, var)
    print(io, ", Time Range: ", time(var)[1], " to ", time(var)[end])
    print(io, ", Units: ", unit(var))
    print(io, ", Size: ", size(var))
    print(io, ")")
end

# Add Base.show methods for pretty printing
function Base.show(io::IO, m::MIME"text/plain", var::T) where {T<:AbstractDataVariable}
    ismissing(var) && return
    print(io, "$T: ")
    print_name(io, var)
    println(io)
    println(io, "  Time Range: ", time(var)[1], " to ", time(var)[end])
    println(io, "  Units: ", unit(var))
    println(io, "  Size: ", size(var))
    println(io, "  Memory Usage: ", Base.format_bytes(Base.summarysize(var)))
    if (m = meta(var)) !== nothing
        println(io, "  Metadata:")
        for (key, value) in sort(collect(m), by=x -> x[1])
            println(io, "    ", key, ": ", value)
        end
    end
end