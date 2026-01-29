# https://docs.astropy.org/en/stable/coordinates/frames.html
# https://docs.sunpy.org/en/stable/reference/coordinates/index.html

"""
A Reference System is a scheme for orienting points in a space and describing how they transform to other systems.

See also: [`AbstractReferenceFrame`](@ref)
"""
abstract type AbstractReferenceSystem end

"""
A specific realization of a reference system.
"""
abstract type AbstractReferenceFrame end

"""
Frames can depend on epoch and planetary orientation models
"""
abstract type TimeDependentFrame <: AbstractReferenceFrame end
