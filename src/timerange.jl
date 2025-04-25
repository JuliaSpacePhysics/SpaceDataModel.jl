using Dates

"""Check if a string is in Day of Year format (YYYY-DDD)."""
is_doy(str) = occursin(r"^(\d{4})-(\d{3})", str)

parse_doy_date(str, i=5) = @views Date(str[1:i-1]) + Day(str[i+1:i+3]) - Day(1)
parse_doy_datetime(str) = @views parse_doy_date(str) + Time(str[10:end])
_parse_date(str) = is_doy(str) ? parse_doy_date(str) : Date(str)
_parse_datetime(str) = is_doy(str) ? parse_doy_datetime(str) : DateTime(str)

parse_datetime(str)::DateTime = 'T' ∉ str ? _parse_date(str) : _parse_datetime(str)