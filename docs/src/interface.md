# Interface

SpaceDataModel.jl provides a set of abstractions and generic functions that can be extended by users to create custom implementations. This page documents these interfaces and provides examples of how to use them.

## References

- [DataAPI.jl](https://github.com/JuliaData/DataAPI.jl): A data-focused namespace for packages to share functions

## Metadata

Generic functions to extend for custom data types:

```@docs; canonical=false
getmeta
setmeta
setmeta!
```