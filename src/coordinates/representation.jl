"""
Abstract base for representing a point in a 3D coordinate system.

# Reference:
- https://docs.astropy.org/en/stable/coordinates/representations.html
- https://github.com/JuliaEarth/CoordRefSystems.jl/blob/main/src/crs.jl
"""
abstract type AbstractRepresentation end

struct Cartesian3 <: AbstractRepresentation end
struct Spherical <: AbstractRepresentation end   # (r, θ, ϕ) or (r, lat, lon)—define explicitly!
struct Geodetic <: AbstractRepresentation end   # (lat, lon, h) on ellipsoid
