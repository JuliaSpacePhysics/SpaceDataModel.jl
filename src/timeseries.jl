"""A time series-focused namespace for packages to share functions"""
module TimeSeriesAPI
using ..SpaceDataModel: dim, @getproperty, unwrap
export tdimnum, timedim, times, tmin, tmax
using Dates: AbstractTime
"""
    tdimnum(x)

Get the time dimension number of object `x`.
"""
function tdimnum(x)
    @warn "Could not guess the time dimension number, assuming last dimension"
    return ndims(x)
end

timedim(x) = dim(x, tdimnum(x))

times(v) = @getproperty v (:times, :time) unwrap(timedim(v))
times(v::AbstractVector{<:AbstractTime}) = v

tmin(v) = minimum(times(v))
tmax(v) = maximum(times(v))

end
