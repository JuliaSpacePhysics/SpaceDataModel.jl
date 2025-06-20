import Base: String

export AbstractCoordinateSystem, AbstractCoordinateVector, getcsys

"""
    AbstractCoordinateSystem

Base abstract type for all coordinate system implementations.
"""
abstract type AbstractCoordinateSystem end

"""
    AbstractCoordinateVector

Base abstract type to represent coordinates in a coordinate systems.
"""
abstract type AbstractCoordinateVector end

"""
    getcsys(x)

Get the coordinate system of `x`.

If `x` is a instance of `AbstractCoordinateSystem`, return `x` itself.
If `x` is a type of `AbstractCoordinateSystem`, return an instance of the coordinate system, i.e. `x()`.

This is a generic function, packages should extend it for their own types.
"""
function getcsys(v)
    return hasfield(typeof(v), :csys) ?
        getfield(v, :csys) : nothing
end

getcsys(::Type{S}) where {S <: AbstractCoordinateSystem} = S()
getcsys(x::AbstractCoordinateSystem) = x

Base.String(::Type{S}) where {S <: AbstractCoordinateSystem} = String(nameof(S))
