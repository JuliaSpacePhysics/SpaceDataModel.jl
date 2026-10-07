struct Dataset{S,B,MD}
    name::String
    selectors::S
    source::B
    metadata::MD
end

"""
    Dataset(name, source; selectors=(;), metadata=NoMetadata(), kw...)

A `name`d dataset with domains for its selectors and a source that materializes it
over a time range via [`getdata`](@ref).

`selectors` maps each selector name to its domain: a single value, a collection, or `Any` for open. Values are spelled as strings.

`name` may carry `{selector}` placeholders, filled when selection pins open domains; a source templates itself the same way.
"""
Dataset(name, source; selectors=(;), metadata=NoMetadata(), kwargs...) =
    Dataset(String(name), Selectors(selectors), source, merge(metadata, kwargs))

Base.getindex(ds::Dataset, var::Union{AbstractString,Symbol}) = Product(ds, var)

selectors(ds) = ds.selectors

getdata(ds::Dataset, args...; kwargs...) = getdata(ds.source, args...; kwargs...)
getdata(ds::Dataset, trange::Union{Tuple,Pair,AbstractVector}; kwargs...) = getdata(ds, trange...; kwargs...)

available(ds::Dataset, args...; kwargs...) = available(ds.source, args...; kwargs...)

"""
    Archive(pattern, reader=(paths, t0, t1) -> paths)

A source mirroring a URL-per-step archive: [`remotefiles`](@ref) enumerates,
[`localize`](@ref) caches, `reader(paths, t0, t1)` opens and returns data over `[t0, t1)`.

Unpublished steps are dropped, a gap being normal; a range publishing nothing throws, since no
reader can open an empty file list.
"""
struct Archive{P,R}
    pattern::P
    reader::R
end

Archive(pattern) = Archive(pattern, (paths, t0, t1) -> paths)

function getdata(a::Archive, t0, t1; version="*", refresh=false, dir=datadir(), update=false, ntasks=4)
    from, to = _time(t0), _time(t1)
    urls = remotefiles(a.pattern, from, to; refresh, version)
    isempty(urls) && _no_files(a.pattern, from, to; version)
    return a.reader(localize(urls; dir, update, ntasks), from, to)
end

# The default `==` is `===`, which compares mutable fields (vectors, dicts) by identity.
# `isequal` defaults to `==`, which disagrees with `hash` on NaN and signed-zero fields.
for T in (:DatePart, :FilePattern, :Dataset, :Archive)
    @eval Base.:(==)(a::$T, b::$T) = eqfields(a, b)
    @eval Base.isequal(a::$T, b::$T) = eqfields(a, b, isequal)
    @eval Base.hash(x::$T, h::UInt) = hashfields(x, h)
end

(ds::Dataset)(t0, t1; kwargs...) = getdata(ds, t0, t1; kwargs...)

available(a::Archive, args...; kw...) = available(a.pattern, args...; kw...)
remotefiles(a::Archive, args...; kw...) = remotefiles(a.pattern, args...; kw...)
remotefiles(ds::Dataset, args...; kwargs...) = remotefiles(ds.source, args...; kwargs...)

# Selection pins a dataset by rebuilding its source with the pinned values (`pin`).
_bind(src, fills) = src
_bind(a::Archive, fills) = Archive(_bind(a.pattern, fills), a.reader)

Base.show(io::IO, ds::Dataset) = print(io, name(ds), " ", selectors(ds))
