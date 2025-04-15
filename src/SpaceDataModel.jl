module SpaceDataModel
using Accessors: @set
import Base: size, ∘
import Base: push!, insert!

export AbstractModel, AbstractProject, AbstractInstrument, AbstractProduct, AbstractDataSet
export AbstractDataVariable
export Project, Instrument, DataSet, LDataSet, Product
export abbr

name(v) = v.name
meta(v) = v.meta
units(v) = nothing

include("utils.jl")
include("types.jl")
include("dataset.jl")
include("product.jl")
include("variable.jl")
include("methods.jl")

end
