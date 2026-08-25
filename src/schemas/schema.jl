"""
    MetadataSchema

Abstract type mapping semantic keys (`:name`, `:unit`, `:desc`, …) to metadata keys of a format. 
Subtypes define `rules(schema)`. See `docs/src/schema_guide.md`.
"""
abstract type MetadataSchema end

Base.keys(schema::MetadataSchema) = keys(rules(schema))
Base.haskey(schema::MetadataSchema, key) = haskey(rules(schema), key)
Base.getindex(schema::MetadataSchema, key) = get(rules(schema), key, nothing)
(s::MetadataSchema)(data) = SchemaLookup(s, data)
(s::MetadataSchema)(data, key) = SchemaLookup(s, data)[key]

"""
    SchemaDict(schema, data)
    SchemaDict(schema, pairs::Pair...)

Dict tagged with a `MetadataSchema`, recovered by [`get_schema`](@ref).
"""
struct SchemaDict{S, K, V, D <: AbstractDict{K, V}} <: AbstractDict{K, V}
    schema::S
    data::D
end

SchemaDict(schema, pairs::Pair...) = SchemaDict(schema, Dict(pairs...))

for f in (:length, :iterate, :getindex, :setindex!, :get)
    @eval Base.$f(t::SchemaDict, args...) = Base.$f(t.data, args...)
end

"""
    get_schema(data)

Get the metadata schema for `data`. Returns the tagged schema if metadata is
a [`SchemaDict`](@ref), otherwise infers from content (`"CATDESC"` ⇒ `ISTPSchema`),
falling back to `DefaultSchema`.
"""
get_schema(data) = _get_schema(getmeta(data))
get_schema(f::Function, args...) = get_schema(f(args...))
_get_schema(::Any) = DefaultSchema()
_get_schema(t::SchemaDict) = t.schema
function _get_schema(meta::AbstractDict)
    return haskey(meta, "CATDESC") ? ISTPSchema() : DefaultSchema()
end

# Helper struct for lookup without materializing a dictionary
struct SchemaLookup{S, D}
    schema::S
    data::D
end

@inline Base.getindex(sl::SchemaLookup, key) = get(sl, key)
@inline function Base.get(sl::SchemaLookup, key, default = nothing)
    return @something(
        resolve(sl.data, key),
        resolve(sl.data, sl.schema[key]),
        Some(default)
    )
end

Base.haskey(sl::SchemaLookup, key) = haskey(sl.schema, key) || haskey(getmeta(sl.data), key)

# Accessor pattern for `resolve`: apply `accessor(data)` first, then
# resolve `lookup` against the result.
struct Via{F, L}
    accessor::F
    lookup::L
end

struct DefaultSchema <: MetadataSchema end
rules(::DefaultSchema) = _DEFAULT_MAPPING

const _DEFAULT_MAPPING = (
    name = "name" => SpaceDataModel.name,
    unit = "unit",
)

include("istp.jl")

"""
    resolve(data, lookup)

Resolve metadata value from `data` using `lookup`.

# Patterns
- `"key"` / `:key`: direct metadata lookup
- `("k1", "k2", ...)`: priority lookup, first hit wins
- `Via(f, lookup)`: `f(data)` then resolve `lookup` on the result
- `lookup => default`: use `default` (or `default(data)`) if lookup misses
- `f::Function`: call `f(data)`
"""
resolve(_, ::Nothing) = nothing
resolve(data, lookup::Union{String, Symbol}) = _get(getmeta(data), lookup, nothing)
resolve(data, lookup::Function) = lookup(data)
resolve(data, v::Via) = resolve(v.accessor(data), v.lookup)

function resolve(data, lookup::Tuple)
    for key in lookup
        val = resolve(data, key)
        isnothing(val) || return val
    end
    return nothing
end

function resolve(data, lookup::Pair)
    _second(x, _) = x
    _second(f::Function, data) = f(data)

    return @something resolve(data, lookup.first) _second(lookup.second, data)
end
