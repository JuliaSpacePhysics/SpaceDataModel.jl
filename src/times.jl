# Reference: https://github.com/JuliaAPlavin/DateFormats.jl
module Times
using Dates
using Dates: AbstractTime
export ≃, cadence, parse_datetime

/ₜ(x, n) = x / n
/ₜ(x::AbstractTime, n) = Nanosecond(round(Int64, Dates.tons(x) / n))

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
    @assert N > 1
    dt0 = /ₜ(times[N] - times[1], N - 1)
    check && @inbounds for i in 1:(N - 1)
        dt = times[i + 1] - times[i]
        @assert ≃(dt, dt0; rtol) "Data is not approximately uniformly sampled."
    end
    return dt0
end
function cadence(T::Type{<:Real}, times; kw...)
    dt = cadence(times; kw...)
    return dt isa AbstractTime ? T(Dates.tons(dt) / 1.0e9) : T(dt)
end


#########
# Parsing
#########

"""Check if a string is in Day of Year format (YYYY-DDD)."""
is_doy(str) = occursin(r"^(\d{4})-(\d{3})", str)

parse_doy_date(str, i = 5) = @views Date(str[1:(i - 1)]) + Day(str[(i + 1):(i + 3)]) - Day(1)
parse_doy_datetime(str) = @views parse_doy_date(str) + Time(str[10:end])
_parse_date(str) = is_doy(str) ? parse_doy_date(str) : Date(str)
_parse_datetime(str) = is_doy(str) ? parse_doy_datetime(str) : DateTime(str)

parse_datetime(str)::DateTime = 'T' ∉ str ? _parse_date(str) : _parse_datetime(str)

end
