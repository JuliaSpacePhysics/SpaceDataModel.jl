# Reference: https://github.com/JuliaAPlavin/DateFormats.jl
module Times
using Dates
using Dates: AbstractTime
export ≃, cadence, parse_datetime

/ₜ(x, n) = x / n
/ₜ(x::AbstractTime, n) = Nanosecond(round(Int64, Dates.tons(x) / n))

*ₜ(x, n) = x * n
*ₜ(x::AbstractTime, n) = Nanosecond(round(Int64, Dates.tons(x) * n))

# workaround for `no method matching isapprox(::Nanosecond, ::Nanosecond)`
≃(x, y; kw...) = isapprox(x, y; kw...)
≃(x::AbstractTime, y; kw...) = isapprox(Dates.tons(x), Dates.tons(y); kw...)

"""
    cadence(times; rtol=1.0e-3, check=true)
    cadence(T<:Real, times; rtol=1.0e-3, check=true)

Return the time step of uniformly sampled `times`.

If `check=true`, validates that samples are approximately uniform within `rtol`.
Pass a type `T<:Real` to return the cadence in seconds as that type.
"""
cadence(times::AbstractRange) = step(times)
function cadence(times; rtol = 1.0e-3, check = true)
    N = length(times)
    N > 1 || throw(ArgumentError("cadence needs at least two samples, got $N"))
    dt0 = /ₜ(times[N] - times[1], N - 1)
    check && @inbounds for i in 1:(N - 1)
        dt = times[i + 1] - times[i]
        ≃(dt, dt0; rtol) || throw(ArgumentError("Data is not approximately uniformly sampled."))
    end
    return dt0
end
function cadence(T::Type{<:Real}, times; kw...)
    dt = cadence(times; kw...)
    return dt isa AbstractTime ? T(Dates.tons(dt) / 1.0e9) : T(dt)
end

"""Check if a string is in Day of Year format (YYYY-DDD)."""
is_doy(str) = occursin(r"^(\d{4})-(\d{3})", str)

parse_doy_date(str, i = 5) = @views Date(str[1:(i - 1)]) + Day(str[(i + 1):(i + 3)]) - Day(1)
# The result is a `DateTime`, so read the time to the millisecond.
const DOY_TIME_FORMAT = dateformat"HH:MM:SS.s"
parse_doy_datetime(str) = @views parse_doy_date(str) + Time(str[10:end], DOY_TIME_FORMAT)
_parse_date(str) = is_doy(str) ? parse_doy_date(str) : Date(str)

# ISO `T`, or the space and SPEDAS-style `/` also common in space physics.
const SPACE_FORMAT = dateformat"yyyy-mm-dd HH:MM:SS.s"
const SLASH_FORMAT = dateformat"yyyy-mm-dd/HH:MM:SS.s"

function parse_datetime(str)::DateTime
    i = findfirst(c -> c == 'T' || c == ' ' || c == '/', str)
    isnothing(i) && return _parse_date(str)
    is_doy(str) && return parse_doy_datetime(str)
    c = str[i]
    return c == ' ' ? DateTime(str, SPACE_FORMAT) : c == '/' ? DateTime(str, SLASH_FORMAT) : DateTime(str)
end

end
