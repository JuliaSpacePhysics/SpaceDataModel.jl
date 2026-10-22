module SpaceDataModelDimensionalDataExt

import SpaceDataModel
using DimensionalData: AbstractDimArray, AbstractDimStack, Dimension
import DimensionalData as DD
import SpaceDataModel: _merge

_merge(::DD.NoMetadata, d, rest...) = merge(d, rest...)
SpaceDataModel.getmeta(A::Union{AbstractDimArray, AbstractDimStack, Dimension}) = DD.metadata(A)
SpaceDataModel.name(x::Dimension) = DD.name(x)
SpaceDataModel.name(x::AbstractDimArray) = (n = DD.name(x); n isa DD.NoName ? "" : string(n))
SpaceDataModel.dims(x::AbstractDimArray, i::Integer) = (d = DD.dims(x, i); DD.lookup(d) isa DD.NoLookup ? nothing : d)
# A dimension without coordinates still has a name.
SpaceDataModel._dimnum(x::AbstractDimArray, s) = DD.hasdim(x, Symbol(s)) ? DD.dimnum(x, Symbol(s)) : nothing
SpaceDataModel._strings(d::Dimension) = SpaceDataModel._strings(parent(DD.lookup(d)))

end
