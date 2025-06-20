using Documenter
using SpaceDataModel

DocMeta.setdocmeta!(SpaceDataModel, :DocTestSetup, :(using SpaceDataModel); recursive = true)

makedocs(
    sitename = "SpaceDataModel.jl",
    format = Documenter.HTML(),
    modules = [SpaceDataModel],
    pages = [
        "Home" => "index.md",
        "Interface" => "interface.md",
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
