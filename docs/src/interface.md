# Interface

SpaceDataModel.jl provides a set of abstractions and generic functions that can be extended by users to create custom implementations. This page documents these interfaces and provides examples of how to use them.

## References

- [DataAPI.jl](https://github.com/JuliaData/DataAPI.jl): A data-focused namespace for packages to share functions

## Metadata

The package exports the following functions for metadata handling:

- [`getmeta`](@ref): Get metadata for an object
- [`setmeta`](@ref): Update metadata for an object
- [`setmeta!`](@ref): Update metadata for an object in-place

These functions are generic and can be extended to support custom data types.

```@docs; canonical=false
getmeta
setmeta
setmeta!
```