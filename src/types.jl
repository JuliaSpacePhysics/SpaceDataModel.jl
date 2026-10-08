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
    Registry(name, datasets; defaults=(;), metadata=NoMetadata(), kw...)

A relation of [`Dataset`](@ref)s: rows sharing a selector vocabulary. 
A mission, an instrument, or any other grouping is a `Registry`.
"""
struct Registry{D,MD}
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
Base.keys(reg::Registry) = [name(ds) for ds in values(reg)]
Base.values(reg::Registry) = values(reg.datasets)

function Base.getindex(reg::Registry, id::AbstractString)
    for ds in values(reg)
        name(ds) == id && return ds
    end
    _unknown_id(name(reg), keys(reg), id)
end

@noinline function _unknown_id(label, ids, id)
    near = filter(k -> occursin(lowercase(id), lowercase(k)), ids)
    hint = isempty(near) ? "$(length(ids)) ids, e.g. $(join(first(ids, 5), ", "))" : "did you mean $(join(first(near, 10), ", "))?"
    throw(ArgumentError("$label: no id $(repr(id)); $hint"))
end

abstract type AbstractEvent end

@kwdef struct Event{A,T,M} <: AbstractEvent
    data::A
    start::T
    stop::T
    metadata::M = NoMetadata()
end
