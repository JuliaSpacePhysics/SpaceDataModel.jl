# https://github.com/JuliaGeo/CommonDataModel.jl/blob/main/src/types.jl

abstract type AbstractModel end
abstract type AbstractProject <: AbstractModel end
abstract type AbstractInstrument <: AbstractModel end
abstract type AbstractProduct <: AbstractModel end
abstract type AbstractDataSet <: AbstractProduct end

"""
    Project <: AbstractProject

A representation of a project or mission containing instruments and datasets.

# Fields
- `name`: The name of the project
- `metadata`: Additional metadata
- `instruments`: Collection of instruments
- `datasets`: Collection of datasets
"""
mutable struct Project <: AbstractProject
    name::String
    metadata::Dict
    instruments::Dict
    datasets::Dict
end

"keyword-based constructor"
Project(; name="", instruments=Dict(), datasets=Dict(), metadata=Dict(), kwargs...) = Project(name, merge(metadata, Dict(kwargs)), instruments, datasets)

"""
    Instrument <: AbstractInstrument

# Fields
- `name`: The name of the instrument
- `metadata`: Additional metadata
- `datasets`: Collection of datasets
"""
struct Instrument <: AbstractInstrument
    name::String
    metadata::Dict
    datasets::Dict
end

"keyword-based constructor"
Instrument(; name="", metadata=Dict(), datasets=Dict(), kwargs...) = Instrument(name, merge(metadata, Dict(kwargs)), datasets)

"Construct an `Instrument` from a dictionary."
Instrument(d::Dict) = Instrument(; symbolify(d)...)

name(m::AbstractModel) = m.name
_repr(m::AbstractModel) = name(m)
_repr(m) = m

Base.insert!(p::Project, i, v::AbstractInstrument) = (p.instruments[i] = v; p)
Base.insert!(p::Union{Project,Instrument}, i, v::AbstractDataSet) = (p.datasets[i] = v; p)
Base.push!(p::Union{Project,Instrument}, v) = insert!(p, name(v), v)

Base.show(io::IO, p::T) where {T<:AbstractModel} = print(io, name(p))

function Base.show(io::IO, ::MIME"text/plain", p::T) where {T<:AbstractModel}
    printstyled(io, T, ": "; bold=true)
    printstyled(io, name(p), color=:yellow)
    println(io)

    for field in setdiff(fieldnames(T), (:name, :format))
        ff = getfield(p, field)
        if ff isa Dict || ff isa Vector || ff isa Tuple
            print(io, titlecase("  $field"))
            println(io, " (", typeof(ff), "):")
            for (k, v) in pairs(ff)
                print(io, "    ", k, ": ")
                println(io, v)
            end
        else
            print(io, titlecase("  $field"), ": ")
            println(io, ff)
        end
    end
end

