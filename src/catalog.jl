# https://spase-group.org/data/model/spase-2.7.0/spase-2_7_0_xsd.html#http___www.spase-group.org_data_schema_Spase_Catalog
# Listing of events or observational notes.
abstract type AbstractCatalog <: AbstractModel end
abstract type AbstractEvent <: AbstractModel end

@kwdef struct Event{A,T,M} <: AbstractEvent
    data::A
    start::T
    stop::T
    metadata::M = NoMetadata()
end

(P::AbstractProduct)(e::Event) = P(e.start, e.stop)
