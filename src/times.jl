# Reference: https://github.com/JuliaAPlavin/DateFormats.jl
module Times
using Dates
export parse_datetime

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
