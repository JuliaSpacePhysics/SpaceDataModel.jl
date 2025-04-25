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
function Project(; name="", instruments=Dict(), datasets=Dict(), metadata=Dict(), kwargs...)
    _meta = compat_dict(String, metadata, kwargs)
    Project(name, _meta, instruments, datasets)
end

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

Base.insert!(p::Project, i, v::AbstractInstrument) = (p.instruments[i] = v; p)
Base.insert!(p::Union{Project,Instrument}, i, v::AbstractDataSet) = (p.datasets[i] = v; p)
Base.push!(p::Union{Project,Instrument}, v) = insert!(p, name(v), v)
Base.get(var::AbstractModel, s, d=nothing) = get(meta(var), s, d)
Base.get(f::Function, var::AbstractModel, s) = get(f, meta(var), s)

Base.show(io::IO, p::T) where {T<:AbstractModel} = print(io, name(p))

function show_field(io::IO, field, value::T, prefix="  ") where {T<:Union{Dict,Vector,Tuple}}
    println(io, prefix, titlecase(String(field)), " (", T, "):")
    for (k, v) in pairs(value)
        println(io, prefix, "  ", k, ": ", v)
    end
end

function show_field(io::IO, field, value)
    print(io, titlecase("  $field"), ": ")
    println(io, value)
end

function Base.show(io::IO, ::MIME"text/plain", p::T) where {T<:AbstractModel}
    printstyled(io, T, ": "; bold=true)
    printstyled(io, name(p), color=:yellow)
    println(io)

    for field in setdiff(fieldnames(T), (:name, :format))
        ff = getfield(p, field)
        isempty(ff) || show_field(io, field, ff)
    end
end
