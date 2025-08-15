module SpaceDataModelDimensionalDataExt
using DimensionalData: AbstractDimArray, NoMetadata, metadata
import SpaceDataModel: meta, _merge

_merge(::NoMetadata, d, rest...) = merge(d, rest...)
meta(A::AbstractDimArray) = metadata(A)
end
