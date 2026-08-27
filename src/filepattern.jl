using Dates

# A `{}` date format. `Dates` renders every field but `j`, so the body splits into `DateFormat`
# chunks and the widths of `j` runs.
struct DatePart
    body::String  # As written: what `show` reproduces.
    tokens::Vector{Union{DateFormat,Int}}
    stop::Bool  # `{t1:…}`: the step's end rather than its start.
end
DatePart(body::AbstractString, stop::Bool=false) = DatePart(body, _tokens(body), stop)

Base.:(==)(a::DatePart, b::DatePart) = eqfields(a, b)

# A keyword placeholder; `case` is 'U'/'L' for `{name|U}`/`{name|L}`, '-' for `{name}`.
struct KeyPart
    name::Symbol
    case::Char
end
_apply(k::KeyPart, v) = (s = string(v); k.case == 'U' ? uppercase(s) : k.case == 'L' ? lowercase(s) : s)
_kpstr(k::KeyPart) = k.case == '-' ? string(k.name) : string(k.name, '|', k.case)

const _Part = Union{String,DatePart,KeyPart}

"""
    FilePattern(pattern; cadence=Day(1), kw...)

A template for the names of an archive's files, one per `cadence`.

Text in `{}` is a placeholder: `{t:fmt}` renders the step's start through the `Dates` format `fmt`
(`{t:mm-dd}`, `{t:yyyyjjj}` with `j` for day of year) and `{t1:fmt}` the last instant it covers, for
archives naming both ends. A name without a format is a keyword; `{name|U}` and `{name|L}` render
its value upper- or lowercased. Everything else is literal.

Keywords may be filled at construction, when specializing, or at the call; every one must be filled
before a name is rendered. Filling a keyword with `"*"` leaves a wildcard for [`resolve_url`](@ref)
to match against the archive's listing.

```jldoctest
julia> using Dates

julia> FilePattern("g13_xrs_1m_{t:yyyymm}01_{t1:yyyymmdd}.nc"; cadence=Month(1))(Date(2012, 2))
"g13_xrs_1m_20120201_20120229.nc"
```
"""
struct FilePattern{P<:Period}
    parts::Vector{_Part}
    cadence::P
end

Base.:(==)(a::FilePattern, b::FilePattern) = eqfields(a, b)

function FilePattern(pattern::AbstractString; cadence=Day(1), kw...)
    parts = _parse_pattern(pattern)
    _repeats(parts, cadence) &&
        throw(ArgumentError("consecutive $cadence steps name the same file in $(repr(pattern)); its date fields cannot tell them apart"))
    return FilePattern(parts, cadence)(; kw...)
end

_bind(p::FilePattern, fills) =
    FilePattern(_merge(_Part[x isa KeyPart && haskey(fills, x.name) ? _apply(x, fills[x.name]) : x for x in p.parts]), p.cadence)
(p::FilePattern)(; kw...) = _bind(p, kw)

# Fuse adjacent literals so rendering walks fewer parts.
function _merge(parts)
    out = _Part[]
    for x in parts
        x isa String && !isempty(out) && out[end] isa String ? (out[end] *= x) : push!(out, x)
    end
    return out
end

"""Fill keywords and `t`, giving a URL."""
(p::FilePattern)(t; kw...) = isempty(kw) ? _render(p, t) : p(; kw...)(t)

function _tokens(body)
    ts = Union{DateFormat,Int}[]
    i = firstindex(body)
    for m in eachmatch(r"j+", body)
        m.offset > i && push!(ts, DateFormat(body[i:prevind(body, m.offset)]))
        push!(ts, length(m.match))
        i = m.offset + ncodeunits(m.match)
    end
    i <= lastindex(body) && push!(ts, DateFormat(body[i:end]))
    return ts
end

function _format(io::IO, d::DatePart, dt)
    for tok in d.tokens
        tok isa Int ? print(io, string(dayofyear(dt); pad=tok)) : Dates.format(io, dt, tok)
    end
end

# Fill `{key}`, `{key|U}` and `{key|L}` placeholders in a string; unfilled ones stay as written.
# Delimiters are ASCII, so byte offsets around them are valid indices in any UTF-8 string.
function _format(pattern::AbstractString, fills)
    isempty(fills) && return String(pattern)
    io = IOBuffer(sizehint=ncodeunits(pattern))
    i = j = 1
    while (j = findnext('{', pattern, j)) !== nothing
        k = findnext('}', pattern, j)
        isnothing(k) && break
        b = min(something(findnext('|', pattern, j), k), k)
        key, case = Symbol(SubString(pattern, j + 1, b - 1)), SubString(pattern, b + 1, k - 1)
        start, j = j, k + 1
        haskey(fills, key) && case in ("", "U", "L") || continue
        s = string(fills[key])
        print(io, SubString(pattern, i, start - 1), case == "U" ? uppercase(s) : case == "L" ? lowercase(s) : s)
        i = j
    end
    print(io, SubString(pattern, i))
    return String(take!(io))
end

# Whether one step's name equals the next's, which would make a whole range fetch a single file.
function _repeats(parts, cadence)
    dates = [x for x in parts if x isa DatePart]
    isempty(dates) && return false
    at(t) = sprint(io -> foreach(d -> _format(io, d, d.stop ? t + cadence - Millisecond(1) : t), dates))
    t = DateTime(2001)  # Aligned to every usual cadence; a Monday, so `Week` steps land on boundaries.
    return at(t) == at(t + cadence)
end

function _parse_pattern(s::AbstractString)
    parts = _Part[]
    i = firstindex(s)
    while true
        j = findnext('{', s, i)
        if isnothing(j)
            i <= lastindex(s) && push!(parts, s[i:end])
            return parts
        end
        k = findnext('}', s, j)
        isnothing(k) && throw(ArgumentError("unterminated '{' in pattern $(repr(s))"))
        j > i && push!(parts, s[i:prevind(s, j)])
        push!(parts, _placeholder(s[nextind(s, j):prevind(s, k)], s))
        i = nextind(s, k)
    end
end

function _placeholder(body, s)
    isempty(body) && throw(ArgumentError("empty placeholder '{}' in pattern $(repr(s))"))
    i = findfirst(':', body)
    if isnothing(i)
        j = findfirst('|', body)
        isnothing(j) && return KeyPart(Symbol(body), '-')
        case = body[nextind(body, j):end]
        case in ("U", "L") ||
            throw(ArgumentError("unknown case modifier in {$body} of pattern $(repr(s)); use |U or |L"))
        return KeyPart(Symbol(body[1:prevind(body, j)]), only(case))
    end
    name = body[1:prevind(body, i)]
    name in ("t", "t1") ||
        throw(ArgumentError("unknown time {$name} in pattern $(repr(s)); use {t:…} or {t1:…}"))
    spec = body[nextind(body, i):end]
    isempty(spec) && throw(ArgumentError("empty date format in {$body} of pattern $(repr(s))"))
    return DatePart(spec, name == "t1")
end

function _render(p::FilePattern, t)
    start = floor(DateTime(t), p.cadence)
    stop = start + p.cadence - Millisecond(1)  # `{t1:…}`: a monthly file reads `…_20101201_20101231.nc`.
    io = IOBuffer()
    for x in p.parts
        x isa String ? write(io, x) :
        x isa DatePart ? _format(io, x, x.stop ? stop : start) :
        throw(ArgumentError("unfilled placeholder {$(_kpstr(x))} in pattern $(repr(_pattern(p)))"))
    end
    return String(take!(io))
end

_pattern(p::FilePattern) = join(x isa String ? x : x isa DatePart ? "{$(x.stop ? "t1" : "t"):$(x.body)}" : "{$(_kpstr(x))}" for x in p.parts)

Base.show(io::IO, p::FilePattern) = print(io, "FilePattern(", repr(_pattern(p)), p.cadence == Day(1) ? "" : "; cadence = $(p.cadence)", ")")
