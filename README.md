# SpaceDataModel.jl

[![DOI](https://zenodo.org/badge/958430775.svg)](https://doi.org/10.5281/zenodo.15207556)
[![version](https://juliahub.com/docs/General/SpaceDataModel/stable/version.svg)](https://juliahub.com/ui/Packages/General/SpaceDataModel)

A lightweight Julia package providing a flexible data model for handling space/heliospheric science data. It offers abstractions for organizing space data into hierarchical structures including projects, instruments, datasets, and data variables.

## Quick Start

```julia
using Pkg; Pkg.add("SpaceDataModel")
using SpaceDataModel: Project, Instrument, DataSet, DataVariable

# Create a project
project = Project(; name="Project Name")
instrument = Instrument(; name="Instrument Name")
dataset = DataSet(; name="Dataset Name")
var = DataVariable([1.0, 2.0, 3.0], Dict())

push!(project, instrument, dataset)
push!(instrument, dataset)
dataset["var"] = var
```

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
urls = remotefiles(fgs, "2020-10-01", "2020-10-03"; version="*")  # "*" picks the latest version listed
paths = localize(urls)                          # cached local copies
```

Placeholder syntax and cadence: docstring of `FilePattern` in [`src/filepattern.jl`](src/filepattern.jl); fetching in [`src/remote.jl`](src/remote.jl).

## References

- [SPASE Model](https://spase-group.org/data/model/index.html)
- [HAPI Data Access Specification](https://github.com/hapi-server/data-specification)
- [CommonDataModel.jl](https://github.com/JuliaGeo/CommonDataModel.jl): abstract types for GRIB, NetCDF, geoTiff and Zarr files
- [NetCDF Data Model](https://docs.unidata.ucar.edu/netcdf-c/current/netcdf_data_model.html)
