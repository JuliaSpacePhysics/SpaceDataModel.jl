# Metadata Schemas

A mapping layer that resolves semantic attribute names (`:name`, `:unit`, `:desc`, …)
against metadata from heterogeneous data formats (ISTP, HAPI, Madrigal).

## Components

- **`MetadataSchema`** — abstract type. Concrete subtypes: `DefaultSchema`, `ISTPSchema`.
- **`rules(schema)`** — returns a mapping from semantic keys to lookup patterns.
- **`resolve(data, lookup)`** — evaluates a lookup pattern against `data`.
- **`SchemaLookup`** — lazy proxy returned by `schema(data)`; resolves keys on access.
- **`SchemaDict`** — `AbstractDict` carrying a schema.
- **`get_schema(data)`** — selects the appropriate schema for `data`.

## Lookup Patterns

`resolve(data, lookup)` accepts:

| Pattern                | Meaning                                       |
| ---------------------- | --------------------------------------------- |
| `"key"` / `:key`       | direct metadata lookup                        |
| `("k1", "k2", ...)`    | priority lookup, first hit wins               |
| `Via(f, sublookup)`    | apply `f(data)` then resolve `sublookup`      |
| `lookup => default`    | use `default` (or `default(data)`) on miss    |
| `f::Function`          | call `f(data)`                                |

## Usage

```julia
schema = ISTPSchema()
attrs  = schema(data)        # SchemaLookup
attrs[:unit]                 # "km/s"
attrs[:depend_1_name]        # resolves via Via(depend_1, ...)
get(attrs, :missing, "n/a")  # default on miss
```

## Schema Selection

`get_schema(data)` resolves in order:

1. If metadata is a `SchemaDict`, return its `schema` field.
2. Otherwise, infer from content (`haskey(meta, "CATDESC")` ⇒ `ISTPSchema`).
3. Fall back to `DefaultSchema`.

## Tagging Metadata

Attach a schema at construction so it travels through type conversions:

```julia
meta = SchemaDict(ISTPSchema(), "UNITS" => "km/s", "CATDESC" => "velocity")
arr  = DimArray(values; metadata = meta)
get_schema(arr) === meta.schema   # true
```

## Defining a New Schema

```julia
struct HAPISchema <: MetadataSchema end

rules(::HAPISchema) = (
    name = "name",
    unit = "units",
    desc = "description",
)
```

Producers in downstream packages attach it via `SchemaDict(HAPISchema(), raw_dict)`.
