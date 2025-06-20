# Interface

SpaceDataModel.jl provides a set of abstractions and generic functions that can be extended by users to create custom implementations. This page documents these interfaces and provides examples of how to use them.

## References

- [DataAPI.jl](https://github.com/JuliaData/DataAPI.jl): A data-focused namespace for packages to share functions

## Coordinate Systems

The package exports three key components for coordinate system handling:

- [`AbstractCoordinateSystem`](@ref): Base abstract type for all coordinate system implementations
- [`AbstractCoordinateVector`](@ref): Base abstract type to represent coordinates in a coordinate systems
- [`getcsys`](@ref): Function to retrieve the coordinate system from an object


There are two main approaches to implementing coordinate vectors and their associated systems:

### Approach 1: Explicit Coordinate System Field

Store the coordinate system directly as a field in the vector type:

```julia
# Define a coordinate system
struct GEO <: AbstractCoordinateSystem end

# Define a vector with an explicit coordinate system field
struct CoordinateVector{D, T} <: AbstractCoordinateVector
    data::D
    csys::T
end

# Implementation of getcsys simply returns the stored field
getcsys(x::CoordinateVector) = x.csys
```

### Approach 2: Implicit Coordinate System

Associate a specific coordinate system with a vector type:

```julia
# Define a coordinate system
struct GEO <: AbstractCoordinateSystem end

# Define a vector type specific to a coordinate system
struct GEOVector{D} <: AbstractCoordinateVector
    data::D
end

# Implementation of getcsys returns the appropriate system
getcsys(x::GEOVector) = GEO()
```

Both approaches are highly efficient and provide equivalent performance due to Julia's type inference system.

### Elsewhere

- [CoordRefSystems.jl](https://github.com/JuliaEarth/CoordRefSystems.jl) provides conversions between Coordinate Reference Systems (CRS) for cartography use cases.
- [Geodesy.jl](https://github.com/JuliaGeo/Geodesy.jl) for working with points in various world and local coordinate systems.
- [WCS.jl](https://juliaastro.org/WCS/stable/) : Astronomical World Coordinate System library 