module CoordinateSystem
using StaticArraysCore

export CoordinateVector

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

end