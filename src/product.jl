"""
    Product(dataset, variable; metadata=NoMetadata(), kw...)

A `variable` of a `dataset`: with optional layered metadata (e.g. a plot label override).
"""
struct Product{D,V,MD} <: DataSource
    dataset::D
    variable::V
    metadata::MD
end

Product(dataset, variable; metadata=NoMetadata(), kwargs...) =
    Product(dataset, variable, merge(metadata, kwargs))

Base.parent(p::Product) = p.dataset
name(p::Product) = getmeta(p, "name", p.variable)
_getdata(p::Product, t0, t1; kwargs...) = getdata(parent(p), t0, t1; kwargs...)[p.variable]
available(p::Product, args...; kwargs...) = available(parent(p), args...; kwargs...)


"""
    Transformed(f, source; metadata=NoMetadata(), kw...)

A derived product: [`getdata`](@ref) materializes `source` and applies `f` to the result.
"""
struct Transformed{F,S,MD} <: DataSource
    f::F
    source::S
    metadata::MD
end

Transformed(f, source; metadata=NoMetadata(), kwargs...) =
    Transformed(f, source, merge(metadata, kwargs))

_getdata(t::Transformed, t0, t1; kwargs...) = t.f(getdata(t.source, t0, t1; kwargs...))
available(t::Transformed, args...; kwargs...) = available(t.source, args...; kwargs...)

# Any package method outranks this one
function getdata(x::DataSource, t0, t1; kwargs...)
    from, to = _time(t0), _time(t1)
    from === t0 && to === t1 || return getdata(x, from, to; kwargs...)
    return _getdata(x, t0, t1; kwargs...)
end
_getdata(x, t0, t1; kwargs...) = throw(ArgumentError(
    "getdata not defined for $(typeof(x)); define getdata(::$(typeof(x)), t0::DateTime, t1::DateTime)"))

getdata(x::DataSource, trange::Union{Tuple,Pair,AbstractVector}; kwargs...) = getdata(x, trange...; kwargs...)
(x::DataSource)(args...; kwargs...) = getdata(x, args...; kwargs...)

∘(f, s::DataSource) = Transformed(f, s)
∘(f, t::Transformed) = Transformed(f ∘ t.f, t.source, t.metadata)
