"""
    DataSource

Supertype for anything [`getdata`](@ref) materializes over a time range; contract in the README (Data Sources).
"""
abstract type DataSource end

"""
    AbstractDataset <: DataSource

A `DataSource` whose data is indexable by variable name; `ds[var]` is a [`Product`](@ref).
"""
abstract type AbstractDataset <: DataSource end

"""
    AbstractRegistry

A provider's [`DataSource`](@ref)s keyed by id; a subtype defines `keys(reg)` and `reg[id]`.
"""
abstract type AbstractRegistry end

Base.values(reg::AbstractRegistry) = (reg[k] for k in keys(reg))
Base.length(reg::AbstractRegistry) = length(keys(reg))
Base.haskey(reg::AbstractRegistry, id) = id in keys(reg)
Base.filter(f, reg::AbstractRegistry) = Registry(name(reg), filter(f, collect(values(reg))))

"""
    Registry(name, datasets; defaults=(;), metadata=NoMetadata(), kw...)

A relation of [`Dataset`](@ref)s: rows sharing a selector vocabulary. 
A mission, an instrument, or any other grouping is a `Registry`.
"""
struct Registry{D,MD} <: AbstractRegistry
    name::String
    datasets::D
    metadata::MD
    defaults::Selectors
end

function Registry(; name="", datasets=[], metadata=NoMetadata(), defaults=(;), kwargs...)
    Registry(name, datasets, merge(metadata, kwargs), Selectors(defaults))
end
Registry(name, datasets; kw...) = Registry(; name, datasets, kw...)

Base.getindex(reg::Registry; kw...) = select(reg, Selectors(kw))
Base.keys(reg::Registry) = [name(ds) for ds in values(reg.datasets)]

function Base.getindex(reg::Registry, id::AbstractString)
    for ds in values(reg.datasets)
        name(ds) == id && return ds
    end
    _unknown_id(reg, id)
end

Base.filter(f, reg::Registry) = setproperties(reg, (; datasets=filter(f, collect(values(reg.datasets)))))

@noinline function _unknown_id(reg, id)
    ks = keys(reg)
    near = filter(k -> occursin(lowercase(id), lowercase(k)), ks)
    hint = isempty(near) ? "$(length(ks)) ids, e.g. $(join(first(ks, 5), ", "))" : "did you mean $(join(first(near, 10), ", "))?"
    throw(ArgumentError("$(name(reg)): no id $(repr(id)); $hint"))
end

abstract type AbstractEvent end

@kwdef struct Event{A,T,M} <: AbstractEvent
    data::A
    start::T
    stop::T
    metadata::M = NoMetadata()
end
