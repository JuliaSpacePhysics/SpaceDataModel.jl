"""A time series-focused namespace for packages to share functions"""
module TimeSeriesAPI
using ..SpaceDataModel: AbstractDataVariable, dim, @getproperty, unwrap
export tdimnum, timedim, times, tmin, tmax
using Dates: AbstractTime
"""
    tdimnum(x)

Index of the time dimension of `x`, or `nothing` if `x` has none.

The one method a time series type implements; `timedim`, `times` derive from it.
"""
tdimnum(x) = nothing

hastimedim(x) = !isnothing(tdimnum(x))

function timedim(x)
    t = tdimnum(x)
    isnothing(t) && throw(ArgumentError("$(typeof(x)) has no time dimension (`tdimnum` returned `nothing`)"))
    return dim(x, t)
end

times(v) = _times(v)
times(v::AbstractVector{<:AbstractTime}) = v
_times(v) = unwrap(timedim(v))
_times(v::AbstractDataVariable) = @getproperty v (:times, :time) unwrap(timedim(v))

tmin(v) = minimum(times(v))
tmax(v) = maximum(times(v))

end
