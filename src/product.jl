"""
    Product(dataset, variable; metadata=NoMetadata(), kw...)

A `variable` of a `dataset`: with optional layered metadata (e.g. a plot label override).
"""
struct Product{D,V,MD}
    dataset::D
    variable::V
    metadata::MD
end

Product(dataset, variable; metadata=NoMetadata(), kwargs...) =
    Product(dataset, variable, merge(metadata, kwargs))

Base.parent(p::Product) = p.dataset
name(p::Product) = getmeta(p, "name", p.variable)
getdata(p::Product, t0, t1; kwargs...) = getdata(parent(p), t0, t1; kwargs...)[p.variable]
available(p::Product, args...; kwargs...) = available(parent(p), args...; kwargs...)


"""
    Transformed(f, source; metadata=NoMetadata(), kw...)

A derived product: [`getdata`](@ref) materializes `source` and applies `f` to the result.
"""
struct Transformed{F,S,MD}
    f::F
    source::S
    metadata::MD
end

Transformed(f, source; metadata=NoMetadata(), kwargs...) =
    Transformed(f, source, merge(metadata, kwargs))

getdata(t::Transformed, t0, t1; kwargs...) = t.f(getdata(t.source, t0, t1; kwargs...))
available(t::Transformed, args...; kwargs...) = available(t.source, args...; kwargs...)

getdata(x::Union{AbstractDataset,Product,Transformed}, trange::Union{Tuple,Pair,AbstractVector}; kwargs...) =
    getdata(x, trange...; kwargs...)
(x::Union{AbstractDataset,Product,Transformed})(args...; kwargs...) = getdata(x, args...; kwargs...)

∘(f, s::Union{AbstractDataset,Product}) = Transformed(f, s)
∘(f, t::Transformed) = Transformed(f ∘ t.f, t.source, t.metadata)
