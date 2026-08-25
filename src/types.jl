"""
    Registry(name, datasets; defaults=(;), metadata=NoMetadata(), kw...)

A relation of [`Dataset`](@ref)s: rows sharing a selector vocabulary. 
A mission, an instrument, or any other grouping is a `Registry`.
"""
struct Registry{D,MD,K}
    name::String
    datasets::D
    metadata::MD
    defaults::K
end

function Registry(; name="", datasets=[], metadata=NoMetadata(), defaults=(;), kwargs...)
    Registry(name, datasets, merge(metadata, kwargs), defaults)
end
Registry(name, datasets; kw...) = Registry(; name, datasets, kw...)

Base.getindex(reg::Registry; kw...) = select(reg; kw...)

# https://spase-group.org/data/model/spase-2.7.0/spase-2_7_0_xsd.html#http___www.spase-group.org_data_schema_Spase_Catalog
# Listing of events or observational notes.
abstract type AbstractCatalog end
abstract type AbstractEvent end

@kwdef struct Event{A,T,M} <: AbstractEvent
    data::A
    start::T
    stop::T
    metadata::M = NoMetadata()
end
