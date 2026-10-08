module SpaceDataModel
using ConstructionBase: setproperties
import Base: ∘
using Base: @propagate_inbounds

export Registry, Dataset, Archive, Product, Transformed, Event
export AbstractRegistry, AbstractEvent
export AbstractDataVariable
export AbstractReferenceFrame, AbstractRepresentation
export AbstractCoordinateSystem, AbstractCoordinateVector, getcsys
export getdata, available
export getmeta, setmeta!, setmeta, units
export getdim, tdimnum

# API

"""
    getdata(x, t0, t1; kwargs...)

Materialize `x` over `[t0, t1)`.
"""
function getdata end
getdata(f::Function, args...; kwargs...) = f(args...; kwargs...)

"""
    available(x, t0, t1; kwargs...)

Times in `[t0, t1)` at which `x` has data.
"""
function available end

module Testing
function test_dataset end
end

include("utils.jl")
include("metadata.jl")
include("filepattern.jl");  export FilePattern
include("selectors.jl")
include("types.jl")
include("select.jl")
include("dataset.jl")
include("product.jl")
include("variable_interface.jl")
const dim = getdim = dims # `dim` is the pre-0.4 name.
include("variable.jl")
include("mask.jl")
include("coord.jl")
include("coordinates/reference_frame.jl")
include("coordinates/representation.jl")

include("schemas/schema.jl"); export get_schema, SchemaDict

include("times.jl");        using .Times
include("timeseries.jl");   using .TimeSeriesAPI
using .TimeSeriesAPI: hastimedim
include("timerange.jl");    export TimeRanges, ContinuousTimeRanges
include("remote.jl");       export localize, resolve_url, remotefiles

include("show.jl")
include("workload.jl")

end
