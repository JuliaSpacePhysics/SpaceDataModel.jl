using Documenter
using SpaceDataModel

let readme = read(joinpath(@__DIR__, "..", "README.md"), String)
    readme = replace(readme, "](docs/src/" => "](", "](src/" => "](https://github.com/JuliaSpacePhysics/SpaceDataModel.jl/blob/main/src/")
    write(joinpath(@__DIR__, "src", "index.md"), readme)
end

DocMeta.setdocmeta!(SpaceDataModel, :DocTestSetup, :(using SpaceDataModel); recursive = true)

makedocs(
    sitename = "SpaceDataModel.jl",
    format = Documenter.HTML(),
    modules = [SpaceDataModel],
    pages = [
        "Home" => "index.md",
        "Interface" => "interface.md",
        "Metadata Schemas" => "schema_guide.md",
        "Coordinate Systems" => "coordinate.md",
        "API" => "api.md",
    ],
    checkdocs = :exports,
    doctest = true,
    warnonly = Documenter.except(:doctest),
)

deploydocs(
    repo = "github.com/JuliaSpacePhysics/SpaceDataModel.jl",
    push_preview = true
)
