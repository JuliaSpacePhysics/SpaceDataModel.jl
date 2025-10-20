module SpaceDataModelDimensionalDataExt

import SpaceDataModel
using DimensionalData: AbstractDimArray, TimeDim, dims, Dimension
import DimensionalData as DD
import SpaceDataModel: meta, _merge, timedim, unwrap, name

_merge(::DD.NoMetadata, d, rest...) = merge(d, rest...)
meta(A::AbstractDimArray) = DD.metadata(A)
name(x::Dimension) = DD.name(x)
unwrap(x::Dimension) = parent(x)

function SpaceDataModel.timedim(x::AbstractDimArray, query = nothing)
    query = something(query, TimeDim)
    qdim = dims(x, query)
    return isnothing(qdim) ? dims(x, 1) : qdim
end
end
