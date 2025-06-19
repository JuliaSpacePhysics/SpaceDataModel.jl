# SpaceDataModel

[![Build Status](https://github.com/JuliaSpacePhysics/SpaceDataModel.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaSpacePhysics/SpaceDataModel.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![DOI](https://zenodo.org/badge/958430775.svg)](https://doi.org/10.5281/zenodo.15207556)
[![](https://img.shields.io/badge/%F0%9F%9B%A9%EF%B8%8F_tested_with-JET.jl-233f9a)](https://github.com/aviatesk/JET.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![Coverage](https://codecov.io/gh/JuliaSpacePhysics/SpaceDataModel.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaSpacePhysics/SpaceDataModel.jl)

## Overview

SpaceDataModel.jl is a lightweight Julia package providing a flexible data model for handling space/heliospheric science data. It offers abstractions for organizing space data into hierarchical structures including projects, instruments, datasets, and data variables.

It is used in [SPEDAS.jl](https://github.com/Beforerr/SPEDAS.jl), [Speasy.jl](https://github.com/SciQLop/Speasy.jl), and [HAPIClient.jl](https://github.com/JuliaSpacePhysics/HAPIClient.jl).

## Installation

Using Julia's package manager:

```julia
using Pkg
Pkg.add("SpaceDataModel")
```

## Usage

```julia
using SpaceDataModel

# Create a project
project = Project(; name="Project Name")
instrument = Instrument(; name="Instrument Name")
dataset = DataSet(name="Dataset Name")

push!(project, instrument, dataset)
push!(instrument, dataset)
```

See [Data Model and Project Module - SPEDAS.jl](https://beforerr.github.io/SPEDAS.jl/dev/explanations/data_model/) for more details.

## Features

- Hierarchical organization of data (projects, instruments, datasets)
- Pretty printing for data inspection

## Reference

- [SPASE Model](https://spase-group.org/data/model/index.html)
- [HAPI Data Access Specification](https://github.com/hapi-server/data-specification)
- [CommonDataModel.jl](https://github.com/JuliaGeo/CommonDataModel.jl)
- [NetCDF Data Model](https://docs.unidata.ucar.edu/netcdf-c/current/netcdf_data_model.html)