module SpaceDataModel
using ConstructionBase: ConstructionBase, setproperties
import TimeseriesUtilities: axiskeys, dimnum, rebuild, rekey, tdimnum, times, unwrap
import Base: ∘
using Base: @propagate_inbounds

export Registry, Dataset, Archive, Product, Transformed, Event
export AbstractEvent
export AbstractDataVariable
export getdata, available
export getmeta, setmeta!, setmeta, units
export getdim
VERSION >= v"1.11" && eval(Meta.parse("public NoMetadata, OverlayDict"))

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
const getdim = dims
include("variable.jl")
include("mask.jl")

include("schemas/schema.jl"); export get_schema, SchemaDict

include("times.jl");        using .Times
include("timeseries.jl")
include("remote.jl");       export localize, resolve_url, remotefiles

include("show.jl")
include("workload.jl")

end
