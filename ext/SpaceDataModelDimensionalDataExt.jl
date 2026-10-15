module SpaceDataModelDimensionalDataExt

import SpaceDataModel
using DimensionalData: AbstractDimArray, AbstractDimStack, Dimension
import DimensionalData as DD
import SpaceDataModel: _merge

_merge(::DD.NoMetadata, d, rest...) = merge(d, rest...)
SpaceDataModel.getmeta(A::Union{AbstractDimArray, AbstractDimStack, Dimension}) = DD.metadata(A)
SpaceDataModel.name(x::Dimension) = DD.name(x)
SpaceDataModel.dims(x::AbstractDimArray, i::Integer) = DD.dims(x, i)
SpaceDataModel._strings(d::Dimension) = SpaceDataModel._strings(parent(DD.lookup(d)))

end
