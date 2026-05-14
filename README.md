# SpaceDataModel.jl

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg?logo=julia)](https://JuliaSpacePhysics.github.io/SpaceDataModel.jl/dev/)
[![DOI](https://zenodo.org/badge/958430775.svg)](https://doi.org/10.5281/zenodo.15207556)
[![version](https://juliahub.com/docs/General/SpaceDataModel/stable/version.svg)](https://juliahub.com/ui/Packages/General/SpaceDataModel)

[![Build Status](https://github.com/JuliaSpacePhysics/SpaceDataModel.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaSpacePhysics/SpaceDataModel.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![](https://img.shields.io/badge/%F0%9F%9B%A9%EF%B8%8F_tested_with-JET.jl-233f9a)](https://github.com/aviatesk/JET.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![Coverage](https://codecov.io/gh/JuliaSpacePhysics/SpaceDataModel.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaSpacePhysics/SpaceDataModel.jl)

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
