# Interface
name(v) = @getfield v :name getmeta(v, "name", "")


function unwrap end
unwrap(x) = x

# Dimension
# https://rafaqz.github.io/DimensionalData.jl/stable/api/dimensions
"""
    dim(x, i)
    dim(x, name)

Get the `i`-th dimension of object `x`, or the dimension associated with the given `name`.
The default implementation returns `axes(x, i)`.

A dimension may be time-varying or dependent on other dimensions; in such cases,
the effective size of the corresponding array dimension `ndims` can be greater than 1.
"""
function dim end

dim(x, i) = hasfield(typeof(x), :dims) ? getfield(x, :dims)[i] : axes(x, i)

function dim(x, s::Union{String, Symbol})
    for i in 1:ndims(x)
        d = dim(x, i)
        name(d) == s && return d
    end
    error("Dimension $s not found")
end

"""
    getmeta(x)

Get metadata for object `x`. If `x` does not have metadata, return `NoMetadata()`. 

"""
getmeta(x) = @getfield x (:meta, :metadata) NoMetadata()
getmeta(x::AbstractDict) = x

# like get, but handles NamedTuple
_get(x, key, default) = get(x, key, default)
_get(x::NamedTuple, key::String, default) = get(x, Symbol(key), default)

"""
    getmeta(x, key, default=nothing)

Get metadata value associated with `key` for object `x`, or `default` if `key` is not present.
"""
getmeta(x, key, default = nothing) = _get(meta(x), key, default)

const meta = getmeta # not exported (to be removed)

units(v) = @get(v, "units", nothing)

function unit(v)
    us = units(v)
    return allequal(us) ? only(us) : error("Units are not equal: $us")
end

"""
    setmeta!(x, key => value, ...; symbolkey => value2, ...)
    setmeta!(x, dict::AbstractDict)

Update metadata for object `x` in-place and return `x`. The metadata container must be mutable.

The arguments could be multiple key-value pairs or a dictionary of metadata; keyword arguments are also accepted.

# Examples
```julia
setmeta!(x, :units => "m/s", :source => "sensor")
setmeta!(x, Dict(:units => "m/s", :quality => "good"))
setmeta!(x; units="m/s", calibrated=true)
```

Throws an error if the metadata is not mutable. Use `setmeta` for immutable metadata.
"""
function setmeta! end

function setmeta!(x, args...; kw...)
    m = meta(x)
    ismutable(m) || error("Metadata is not mutable, use `setmeta` instead")
    set!(m, args...; kw...)
    return x
end

"""
    setmeta(x, key => value, ...; symbolkey => value2, ...)
    setmeta(x, dict::AbstractDict)

Update metadata for object `x` for key `key` to have value `value` and return `x`.
"""
function setmeta end

function setmeta(x, args::Pair...; kw...)
    return @set x.metadata = _merge(meta(x), Dict(args...), kw)
end
setmeta(x, dict::AbstractDict) = @set x.metadata = _merge(meta(x), dict)
