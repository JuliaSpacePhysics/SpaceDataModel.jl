"""A time series-focused namespace for packages to share functions"""
module TimeSeriesAPI
using ..SpaceDataModel: dims, unwrap
export tdimnum, timedim, times, tmin, tmax
using Dates: AbstractTime
"""
    tdimnum(x)

Index of the time dimension of `x`, or `nothing` if `x` has none.
"""
tdimnum(x) = nothing

hastimedim(x) = !isnothing(tdimnum(x))

function timedim(x)
    t = tdimnum(x)
    isnothing(t) && throw(ArgumentError("$(typeof(x)) has no time dimension (`tdimnum` returned `nothing`)"))
    return dims(x, t)
end

times(v) = unwrap(timedim(v))
times(v::AbstractVector{<:AbstractTime}) = v

tmin(v) = minimum(times(v))
tmax(v) = maximum(times(v))

end
