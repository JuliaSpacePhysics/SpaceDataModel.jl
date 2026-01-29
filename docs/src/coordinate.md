# Coordinate Systems

Similart to the definitions in [Astropy](https://docs.astropy.org/en/stable/coordinates/definitions.html): we adopt the following terminology:

- A **Coordinate Representation** (chart) is a particular way of describing a unique point in a vector space.
    Common ones include `Cartesian3`, `Spherical`, and `Geodetic` based on [`AbstractRepresentation`](@ref).
- A **Reference System** is a scheme for orienting points in a space and describing how they transform to other systems. 
    For example, the Earth-centered, Earth-fixed (ECEF) reference system tells you (i) origin at the geocenter, (ii) axes rotate with the Earth. But it does not uniquely specify: (i) whether Z is ITRF pole, [Conventional International Origin pole](https://www.wikiwand.com/en/articles/Conventional_International_Origin), "instantaneous rotation axis", etc (ii) whether the axes are aligned to a particular [geodetic datum](https://www.wikiwand.com/en/articles/Geodetic_datum).
- A **Reference Frame** is a specific realization of a reference system (e.g., the [ICRF](https://www.wikiwand.com/en/articles/International_Celestial_Reference_System_and_its_realizations), or J2000 equatorial coordinates).
    For example, GEO is a simplified ECEF realization suitable for space-physics transformations (GEO↔GSE/GSM/SM/MAG). It differs from “true” geodesy realization like [ITRF](https://www.wikiwand.com/en/articles/International_Terrestrial_Reference_System_and_Frame) in that it ignores small corrections like polar motion and uses a simplified Earth rotation model.
- A **Coordinate** is a combination of all of the above that specifies a unique point.

<!-- - A **Coordinate Transformation** is a mapping between different coordinate systems. -->

The package exports the following types [`AbstractReferenceSystem`](@ref), [`AbstractRepresentation`](@ref), [`AbstractReferenceFrame`](@ref), and [`AbstractCoordinateVector`](@ref):

And related functions:

- [`getcsys`](@ref): Function to retrieve the coordinate system from an object


!!! note "Notes" 
    Because of the ambiguity of meaning of "coordinate system", this term should be avoided wherever possible. However, for backward compatibility, we still export [`AbstractCoordinateSystem`](@ref) which serves a practical purpose of combining reference frame and coordinate representation.

## Implementation Approaches

Here we demonstrate two approaches to implementing coordinate vectors and their associated systems:

### Approach 1: Explicit Coordinate System Field

Store the coordinate system directly as a field in the vector type:

```@repl coord
using SpaceDataModel: Cartesian3, AbstractReferenceFrame, AbstractCoordinateVector
import SpaceDataModel: getcsys
# Define a reference frame
struct GEO <: AbstractReferenceFrame end

# Define a vector with an explicit reference frame and representation
struct CoordinateVector{F, R, T} <: AbstractCoordinateVector
    x::T
    y::T
    z::T
end

𝐫 = CoordinateVector{GEO, Cartesian3, Float64}(1, 2, 3)

# Implementation of getcsys
getcsys(::CoordinateVector{F, R}) where {F, R} = (F(), R())
getcsys(𝐫)
```

### Approach 2: Implicit Coordinate System

Associate a specific coordinate system with a vector type:

```@repl coord
# Define a vector type specific to a coordinate system
struct GEOVector{D} <: AbstractCoordinateVector
    data::D
end

# Implementation of getcsys returns the appropriate system
getcsys(::GEOVector) = (GEO(), Cartesian3())
𝐫2 = GEOVector([1, 2, 3])
getcsys(𝐫2)
```

Both approaches are highly efficient and provide equivalent performance due to Julia's type inference system.

```@example coord
using Chairmarks
@b getcsys($𝐫), getcsys($𝐫2)
```

## Elsewhere

- [Astronomical Coordinate Systems (astropy.coordinates) — Astropy](https://docs.astropy.org/en/stable/coordinates/index.html)
- [CoordRefSystems.jl](https://github.com/JuliaEarth/CoordRefSystems.jl) provides conversions between Coordinate Reference Systems (CRS) for cartography use cases.
- [Geodesy.jl](https://github.com/JuliaGeo/Geodesy.jl) for working with points in various world and local coordinate systems.
- [WCS.jl](https://juliaastro.org/WCS/stable/) : Astronomical World Coordinate System library 