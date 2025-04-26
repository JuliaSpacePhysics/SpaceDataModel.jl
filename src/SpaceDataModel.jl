module SpaceDataModel
using Accessors: @set
import Base: size, ∘
import Base: push!, insert!, get, show, getindex, setindex!

export AbstractModel, AbstractProject, AbstractInstrument, AbstractProduct, AbstractDataSet, AbstractCatalog, AbstractEvent
export AbstractDataVariable
export Project, Instrument, DataSet, LDataSet, Product
export Event
export abbr

const SDict = Dict{String,Any}

include("utils.jl")
include("types.jl")
include("dataset.jl")
include("product.jl")
include("variable.jl")
include("catalog.jl")
include("methods.jl")
include("timerange.jl")
include("workload.jl")

# Interface
name(v) = @getfield(v, :name, get(v, "name", ""))
meta(v) = _getfield(v, (:meta, :metadata))
units(v) = @get(v, "units", nothing)
times(v) = _getfield(v, (:times, :time))

end
