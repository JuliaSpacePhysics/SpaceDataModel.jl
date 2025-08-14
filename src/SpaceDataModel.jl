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
name(v) = @getfield v :name get(meta(v), "name", "")
meta(v) = @getfield v (:meta, :metadata) NoMetadata()
units(v) = @get(v, "units", nothing)
times(v) = @getfield v (:times, :time)

function unit(v)
    us = units(v)
    allequal(us) ? only(us) : error("Units are not equal: $us")
end

end
