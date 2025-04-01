module SpaceDataModel

using Unitful: unit
import Base: size

export AbstractModel, AbstractProject, AbstractInstrument, AbstractDataSet
export AbstractDataVariable
export Project, Instrument, DataSet, LDataSet

name(v) = v.name
meta(v) = v.meta

include("types.jl")
include("variable.jl")
include("utils.jl")

print_name(io::IO, var) = printstyled(io, name(var); color=colors(7))
end
