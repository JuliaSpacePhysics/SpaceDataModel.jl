"""
    DataSet <: AbstractDataSet

A concrete dataset with a name, data (parameters), and metadata.
"""
@kwdef struct DataSet{D, MD} <: AbstractDataSet
    name::String = ""
    data::D = NoData()
    metadata::MD = NoMetadata()
end

"""Construct a `DataSet` from a name and data, with optional metadata."""
function DataSet(name, data; metadata=NoMetadata(), kwargs...)
    DataSet(name, data, merge(metadata, kwargs))
end

function fmap(fs, args...; kwargs...)
    map(fs) do f
        !isempty(methods(f)) ? f(args...; kwargs...) : f
    end
end

∘(f::Function, p::DataSet) = @set p.data = f .∘ p.data

data(ds::DataSet) = ds.data
func(ds::AbstractDataSet) = fmap

"""
    LDataSet <: AbstractDataSet

A template for generating datasets with parameterized naming patterns.

# Fields
- `format`: Format string pattern for the dataset name
- `data`: Dictionary of variable patterns
- `metadata`: Additional metadata

# Examples
```julia
using SPEDAS.MMS

# Access FPI dataset specification
lds = mms.datasets.fpi_moms

# Create a concrete dataset with specific parameters
ds = DataSet(lds; probe=1, data_rate="fast", data_type="des")
```

The format string and variable patterns use placeholders like `{probe}`, `{data_rate}`, 
which are replaced with actual values when creating a concrete `DataSet`.
"""
@kwdef struct LDataSet{D, MD} <: AbstractDataSet
    name::String = ""
    data::D = NoData()
    metadata::MD = NoMetadata()
    format::String = ""
end

"""
    DataSet(ld::LDataSet; kwargs...)

Create a concrete `DataSet` from a Dataset template with specified data.

See also: [`LDataSet`](@ref)
"""
function DataSet(ld::LDataSet; kwargs...)
    DataSet(
        uppercase(format_pattern(ld.format; kwargs...)),
        Dict(k => format_pattern(v; kwargs...) for (k, v) in ld.data),
        ld.metadata
    )
end

Base.parent(ds::AbstractDataSet) = ds.data
Base.getindex(ds::DataSet, i::Integer) = _nth(values(ds.data), i)
Base.push!(ds::DataSet, v) = push!(ds.data, v)