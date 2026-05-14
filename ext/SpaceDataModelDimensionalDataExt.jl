module SpaceDataModelDimensionalDataExt

import SpaceDataModel
using DimensionalData: AbstractDimArray, AbstractDimStack, TimeDim, Dimension, Dim
import DimensionalData as DD
import SpaceDataModel: getmeta, _merge, tdimnum, timedim, unwrap, name

_merge(::DD.NoMetadata, d, rest...) = merge(d, rest...)
SpaceDataModel.getmeta(A::Union{AbstractDimArray, AbstractDimStack, Dimension}) = DD.metadata(A)
SpaceDataModel.name(x::Dimension) = DD.name(x)
SpaceDataModel.unwrap(x::Dimension) = unwrap(parent(x))

# A no-error version of `dimnum`
_dimnum(x, dim) = DD.hasdim(x, dim) ? DD.dimnum(x, dim) : nothing

SpaceDataModel.tdimnum(x::AbstractDimArray) = @something(
    _dimnum(x, TimeDim),
    _dimnum(x, Dim{:time}),
    tdimnum(parent(x))
)

end
