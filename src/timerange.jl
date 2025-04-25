using Dates

"""Parse a date in Day of Year format (YYYY-DDD)"""
function tryparse_doy_date(str)
    doy_regex = r"^(\d{4})-(\d{3})$"
    m = match(doy_regex, str)
    if !isnothing(m)
        year = parse(Int, m[1])
        doy = parse(Int, m[2])
        return Date(year) + Day(doy - 1)
    end
    return nothing
end

function tryparse_datetime(str)
    # Check if the string ends with Z and remove it for parsing
    str = rstrip(str, 'Z')
    # Split into date and time parts if T is present
    parts = split(str, "T", limit=2)
    date_part = parts[1]
    # Parse date part
    date = @something(
        tryparse(Date, date_part),
        tryparse_doy_date(date_part)
    )
    length(parts) > 1 ? date + Time(parts[2]) : DateTime(date)
end