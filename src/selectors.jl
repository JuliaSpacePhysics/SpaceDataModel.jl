"""A selector's admissible spellings: one, a set of them, or `Any` for open."""
const Domain = Union{String,Vector{String},Type{Any}}

# Selector each mapped to its [`Domain`](@ref).
# Vector-backed, not a `Dict` or a `NamedTuple`: over the few keys a linear scan beats hashing
struct Selectors <: AbstractDict{Symbol,Domain}
    pairs::Vector{Pair{Symbol,Domain}}
    Selectors(pairs::Vector{Pair{Symbol,Domain}}) = new(pairs)  # keeps `Selectors(kv)` from overwriting the convert fallback
end

_domain(d) = string(d)
_domain(::Type{Any}) = Any
_domain(d::Union{Tuple,AbstractArray,AbstractSet}) = length(d) == 1 ? string(only(d)) : String[string(x) for x in d]

Selectors(kv) = Selectors(Pair{Symbol,Domain}[k => _domain(v) for (k, v) in pairs(kv)])

Base.parent(s::Selectors) = getfield(s, :pairs)
Base.length(s::Selectors) = length(parent(s))
Base.iterate(s::Selectors, i...) = iterate(parent(s), i...)
function Base.get(s::Selectors, k::Symbol, default)
    for (key, d) in parent(s)
        key === k && return d
    end
    return default
end

Base.getproperty(s::Selectors, k::Symbol) = s[k]
Base.propertynames(s::Selectors) = Tuple(keys(s))

# Base's AbstractDict merge hands back a `Dict`
function Base.merge(a::Selectors, b::Selectors)
    isempty(a) && return b
    isempty(b) && return a
    out = Pair{Symbol,Domain}[k => get(b, k, d) for (k, d) in a]
    for p in b
        haskey(a, p.first) || push!(out, p)
    end
    return Selectors(out)
end

_member(::Type{Any}, v) = true
_member(d::String, v) = d == v
_member(d::Vector{String}, v) = v in d

_show_domain(::Type{Any}) = "*"
_show_domain(d::String) = d
_show_domain(d) = "{" * join(d, ",") * "}"

function Base.show(io::IO, s::Selectors)
    isempty(s) && return print(io, "(; )")
    print(io, '(')
    for (i, (k, v)) in enumerate(s)
        Base.show_sym(io, k)
        print(io, " = ")
        show(IOContext(io, :typeinfo => Any), v)
        i < length(s) && print(io, ", ")
    end
    length(s) == 1 && print(io, ',')
    return print(io, ')')
end
