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

include("variable_interface.jl")

end
