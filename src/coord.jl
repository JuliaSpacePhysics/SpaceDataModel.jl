module CoordinateSystem
using StaticArraysCore
import Base: size, getindex, cconvert, unsafe_convert, String

export AbstractCoordinateSystem, CoordinateVector, coord

abstract type AbstractCoordinateSystem end

struct CoordinateVector{T,C} <: FieldVector{3,T}
    x::T
    y::T
    z::T
    sym::C
end

for sys in (:GDZ, :GEO, :GSM, :GSE, :SM, :GEI, :MAG, :SPH, :RLL, :HEE, :HAE, :HEEQ, :J2000)
    @eval struct $sys <: AbstractCoordinateSystem end
    @eval $sys(x, y, z) = CoordinateVector(x, y, z, $sys())
    @eval $sys(x) = CoordinateVector(x..., $sys())
    @eval export $sys
end

@doc """Geocentric Solar Magnetospheric (GSM)\n\nX points sunward from Earth's center. The X-Z plane is defined to contain Earth's dipole axis (positive North).
""" GSM

coord(v::CoordinateVector) = v.sym
Base.String(::Type{S}) where {S<:AbstractCoordinateSystem} = String(nameof(S))
Base.String(::S) where {S<:AbstractCoordinateSystem} = T(S)

# https://github.com/JuliaArrays/StaticArrays.jl/blob/master/src/FieldArray.jl
Base.size(::CoordinateVector) = (3,)
Base.@propagate_inbounds Base.getindex(a::CoordinateVector, i::Int) = getfield(a, i)

# C interface
Base.cconvert(::Type{<:Ptr}, a::CoordinateVector) = Base.RefValue(a)
Base.unsafe_convert(::Type{Ptr{T}}, m::Base.RefValue{FA}) where {T,FA<:CoordinateVector{T}} =
    Ptr{T}(Base.unsafe_convert(Ptr{FA}, m))

end