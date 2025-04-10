module SpaceDataModel
using Accessors: @set
using Unitful: unit
import Base: size, ∘

export AbstractModel, AbstractProject, AbstractInstrument, AbstractProduct, AbstractDataSet
export AbstractDataVariable
export Project, Instrument, DataSet, LDataSet, Product
export abbr

name(v) = v.name
meta(v) = v.meta

include("utils.jl")
include("types.jl")
include("dataset.jl")
include("product.jl")
include("variable.jl")
include("methods.jl")

end
