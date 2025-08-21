# References:
# https://github.com/MakieOrg/AlgebraOfGraphics.jl/blob/master/src/algebra/layer.jl

struct Product{A,F,MD} <: AbstractProduct
    data::A
    transformation::F
    name::Union{String,Symbol}
    metadata::MD
end

function Product(data::A, transformation=identity; name="", metadata=NoMetadata(), kwargs...) where {A}
    new_meta = merge(metadata, kwargs)
    Product(data, transformation, name, new_meta)
end

Base.parent(p::Product) = p.data
func(::AbstractProduct) = identity
func(p::Product) = p.transformation

(p::AbstractProduct)(args...; kwargs...) = func(p)(parent(p), args...; kwargs...)

"""Create a new product with the composed function"""
∘(f, p::AbstractProduct) = @set p.transformation = f ∘ func(p)
∘(p::AbstractProduct, f) = @set p.transformation = func(p) ∘ f

# Allow chaining of transformations with multiple products
∘(g::AbstractProduct, f::AbstractProduct) = @set g.transformation = func(g) ∘ func(f)

function set(p::AbstractProduct; name=nothing, data=nothing, transformation=nothing, metadata=nothing, kwargs...)
    !isnothing(name) && (p = @set p.name = name)
    !isnothing(data) && (p = @set p.data = data)
    !isnothing(transformation) && (p = @set p.transformation = transformation)
    !isnothing(metadata) && (p = @set p.metadata = metadata)
    length(kwargs) > 0 && (p = @set p.metadata = merge(p.metadata, kwargs))
    return p
end

set(p::Product, data, transformation=nothing; kwargs...) = set(p; data, transformation, kwargs...)

function Base.show(io::IO, p::Product)
    n = name(p)
    isempty(n) ? print(io, parent(p)) : print(io, n)
    func(p) !== identity && print(io, " [", func(p), "]")
end