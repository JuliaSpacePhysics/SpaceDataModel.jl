module SpaceDataModel
using Accessors: @set
import Base: size, ∘
import Base: push!, insert!, show, getindex, setindex!, length
import Base: keys, haskey, get
using Base: @propagate_inbounds

export AbstractModel, AbstractProject, AbstractInstrument, AbstractProduct, AbstractDataSet, AbstractCatalog, AbstractEvent
export AbstractDataVariable
export Project, Instrument, DataSet, LDataSet, Product
export Event
export AbstractCoordinateSystem, AbstractCoordinateVector, getcsys
export getmeta, setmeta!, setmeta

include("utils.jl")
include("metadata.jl")
include("types.jl")
include("show.jl")
include("dataset.jl")
include("product.jl")
include("variable.jl")
include("catalog.jl")
include("methods.jl")
include("timerange.jl")
include("coord.jl")
include("workload.jl")

# Interface
name(v) = @getfield v :name meta_name(meta(v))
meta_name(nt::NamedTuple) = get(nt, :name, "")
meta_name(meta) = get(meta, "name", "")

"""
    getmeta(x)

Get metadata for object `x`. If `x` does not have metadata, return `NoMetadata()`. 

"""
getmeta(x) = @getfield x (:meta, :metadata) NoMetadata()

"""
    getmeta(x, key, default=nothing)

Get metadata value associated with object `x` for key `key`, or `default` if `key` is not present.
"""
getmeta(x, key, default = nothing) = get(meta(x), key, default)

meta(x) = getmeta(x) # not exported (to be removed)

function units(v)
    m = getmeta(v)
    return m isa NamedTuple ? get(m, :units, nothing) : get(m, "units", nothing)
end
times(v) = @getfield v (:times, :time)

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

end
