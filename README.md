# SpaceDataModel

[![DOI](https://zenodo.org/badge/958430775.svg)](https://doi.org/10.5281/zenodo.15207556)
[![version](https://juliahub.com/docs/General/SpaceDataModel/stable/version.svg)](https://juliahub.com/ui/Packages/General/SpaceDataModel)

[![Build Status](https://github.com/JuliaSpacePhysics/SpaceDataModel.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaSpacePhysics/SpaceDataModel.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![](https://img.shields.io/badge/%F0%9F%9B%A9%EF%B8%8F_tested_with-JET.jl-233f9a)](https://github.com/aviatesk/JET.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![Coverage](https://codecov.io/gh/JuliaSpacePhysics/SpaceDataModel.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaSpacePhysics/SpaceDataModel.jl)

## Overview

SpaceDataModel.jl is a lightweight Julia package providing a flexible data model for handling space/heliospheric science data. It offers abstractions for organizing space data into hierarchical structures including projects, instruments, datasets, and data variables.

For information on using the package, see the documentation available at https://JuliaSpacePhysics.github.io/SpaceDataModel.jl/dev/.

**Installation**: at the Julia REPL, run `using Pkg; Pkg.add("SpaceDataModel")`

**Documentation**: [![Dev](https://img.shields.io/badge/docs-dev-blue.svg?logo=julia)](https://JuliaSpacePhysics.github.io/SpaceDataModel.jl/dev/)

## Usage

```julia
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
