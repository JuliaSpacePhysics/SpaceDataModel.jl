# SpaceDataModel.jl

[![DOI](https://zenodo.org/badge/958430775.svg)](https://doi.org/10.5281/zenodo.15207556)
[![version](https://juliahub.com/docs/General/SpaceDataModel/stable/version.svg)](https://juliahub.com/ui/Packages/General/SpaceDataModel)

A lightweight data model package for space/heliospheric science: datasets with selector domains and sources that materialize them over a time range.

## Quick Start

```julia
using Pkg; Pkg.add("SpaceDataModel")
using SpaceDataModel

pattern = FilePattern("https://data.elfin.ucla.edu/{probe}/l2/{probe}_l2_epd_{t:yyyymmdd}_v{version}.cdf")
epd = Dataset("epd", Archive(pattern);  # a reader(paths, t0, t1) opens and trims, e.g. Archive(pattern, cdfopen)
    selectors = (; probe = ("ela", "elb")))
reg = Registry("EPD", [epd]; defaults = (; probe = "ela"))

filter(reg; probe = "elb")    # discovery path: keeps matching rows
ds = reg[probe = "elb"]       # select the only matching dataset, or an error listing the domains
getdata(ds, "2021-08-08", "2021-08-09")    # enumerate remote files, cache, open
```

## Data Sources

`getdata(x, t0, t1)` is the one fetch verb; `x` is a `SpaceDataModel.DataSource` or a function with `(t0, t1) -> data`.
`AbstractDataset <: DataSource` adds indexable variables: `ds[var]` is a `Product`.

A package adds a dataset type, or a `DataSource` for a standalone variable:

```julia
struct MyDataset <: SpaceDataModel.AbstractDataset; id::String; end
SpaceDataModel.getdata(ds::MyDataset, t0::DateTime, t1::DateTime; kw...) = ...    # all variables, indexable by name
SpaceDataModel.getdata(p::Product{MyDataset}, t0::DateTime, t1::DateTime; kw...) = ...  # optional: fetch `p.variable` directly
```

`getdata` converts time strings (`"2020-001"`, `"2020-01-01 12:00"`) and `Date`s to `DateTime` before dispatching on a `DataSource`.

Contract: data covers `[t0, t1)` (half-open); `getdata(ds, t0, t1)[v]` equals `getdata(ds[v], t0, t1)`.
A range without data should return an empty variable (`Archive` throws instead: it has no file to build one from).
Check a dataset against the contract in its tests with `using Test; SpaceDataModel.Testing.test_dataset(ds, var, t0, t1; empty)`.

`Dataset` is the `AbstractDataset` for file archives: a name templated over selector domains, and a source such as `Archive`, see Quick Start.

## Metadata Schemas

Resolve semantic attributes (`:name`, `:unit`, `:desc`, …) against heterogeneous metadata formats (ISTP, HAPI, Madrigal).

```julia
using SpaceDataModel: ISTPSchema, get_schema

# data is anything carrying metadata (raw Dict, DimArray, DataVariable, …)
schema = ISTPSchema()
attrs = schema(data)
attrs[:unit]
attrs[:desc]

# Or auto-detect the schema from the metadata content
get_schema(data)
```

See [`docs/src/schema_guide.md`](docs/src/schema_guide.md) for lookup patterns and extending to new formats.

## Remote Files

Describe an archive's file names with a template, then resolve and download by time range.

```julia
using SpaceDataModel: FilePattern, remotefiles, localize

p = FilePattern("https://data.elfin.ucla.edu/{probe}/{level}/fgm/survey/{t:yyyy}/{probe}_{level}_fgs_{t:yyyymmdd}_v{version}.cdf")
fgs = p(; probe="ela", level="l1")              # fill keywords now or at the call
fgs("2020-10-01"; version="03")                 # one file name
urls = remotefiles(fgs, "2020-10-01", "2020-10-03")  # `version` defaults to "*": the latest listed
paths = localize(urls)                          # cached local copies
```

Placeholder syntax and cadence: docstring of `FilePattern` in [`src/filepattern.jl`](src/filepattern.jl); fetching in [`src/remote.jl`](src/remote.jl).

## References

- [SPASE Model](https://spase-group.org/data/model/index.html)
- [HAPI Data Access Specification](https://github.com/hapi-server/data-specification)
- [CommonDataModel.jl](https://github.com/JuliaGeo/CommonDataModel.jl): abstract types for GRIB, NetCDF, geoTiff and Zarr files
- [NetCDF Data Model](https://docs.unidata.ucar.edu/netcdf-c/current/netcdf_data_model.html)
