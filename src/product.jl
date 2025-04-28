struct Product{A,F} <: AbstractProduct
    data::A
    transformation::F
    name::Union{String,Symbol}
    metadata::Any
    function Product(data::A, transformation::F, name="", metadata=Dict(); kwargs...) where {A,F}
        metadata = merge(metadata, kwargs)
        new{A,F}(data, transformation, name, metadata)
    end
end

function Product(data; transformation=identity, name="", metadata=Dict(), kwargs...)
    Product(data, transformation, name, metadata; kwargs...)
end

data(p::Product) = p.data
func(p::AbstractProduct) = identity
func(p::Product) = p.transformation

(p::AbstractProduct)(args...; kwargs...) = func(p)(data(p), args...; kwargs...)

"""Create a new product with the composed function"""
∘(f, p::AbstractProduct) = @set p.transformation = f ∘ func(p)
∘(p::AbstractProduct, f) = @set p.transformation = func(p) ∘ f

# Allow chaining of transformations with multiple products
∘(g::AbstractProduct, f::AbstractProduct) = @set g.transformation = func(g) ∘ func(f)

function set(ds::AbstractProduct, args...; name=nothing, data=nothing, kwargs...)
    !isnothing(name) && (ds = @set ds.name = name)
    !isnothing(data) && (ds = @set ds.data = data)
    (!isnothing(kwargs) || !isnothing(args)) && (ds = @set ds.metadata = set(ds.metadata, args...; kwargs...))
    return ds
end

function set!!(ds::Product, args...; name=nothing, data=nothing, kwargs...)
    !isnothing(name) && (ds = @set ds.name = name)
    !isnothing(data) && (ds = @set ds.data = data)
    set!(ds.metadata, args...; kwargs...)
    ds
end

function Base.show(io::IO, p::Product)
    n = name(p)
    isnothing(n) ? print(io, data(p)) : print(io, n)
    func(p) !== identity && print(io, " [", func(p), "]")
end