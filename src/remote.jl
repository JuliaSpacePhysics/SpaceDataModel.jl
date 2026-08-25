using Dates
using Downloads: Downloads, request

datadir() = get(ENV, "SPACE_DATA_DIR", joinpath(homedir(), ".cache", "spacedata"))

"""
    localize(url; dir=datadir(), update=false) -> String
    localize(urls; ntasks=4, kw...) -> Vector{String}

Return a local path for each URL, downloading files missing from the cache.

Set the `SPACE_DATA_DIR` environment variable to override the default cache directory.

Set `update = true` to force re-download, or a `Period` to refetch if the local copy is older.
"""
localize(urls::AbstractVector; ntasks=4, kw...) =
    convert(Vector{String}, asyncmap(url -> localize(url; kw...), urls; ntasks))

function localize(url; dir=datadir(), update=false)
    _stale(_, update::Bool) = update
    _stale(path, age::Period) = now() - unix2datetime(mtime(path)) > age

    path = local_path(url, dir)
    return isfile(path) && !_stale(path, update) ? path : _download_atomic(url, path)
end

"""
    resolve_url(url; refresh=false)

Concrete URL for `url`, where each `*` in the file name is replaced with the highest version field
published in the directory, or `nothing` if the directory lists no such file.

A field matches any width and any separator (e.g., `v03`, `v03.06`, `v03_01`, `v1.1.10`). 
A name may carry more than one, as MAVEN's `…_v02_r00.cdf` does; fields rank left to right.
"""
function resolve_url(url; refresh=false)
    occursin('*', url) || return url
    name = basename(url)
    dir = url[1:(end-length(name))]
    occursin('*', dir) &&
        throw(ArgumentError("wildcard outside the file name of $(repr(url)); a directory cannot be listed unless it is named"))
    re = _name_regex(name)
    names = tryreaddir(dir; refresh)
    isnothing(names) && return nothing
    best, bestkey = nothing, nothing
    for n in names
        m = match(re, n)
        isnothing(m) && continue
        key = mapreduce(_numkey, vcat, m.captures)
        if isnothing(bestkey) || key > bestkey
            best, bestkey = n, key
        end
    end
    return isnothing(best) ? nothing : dir * best
end

"""
    remotefiles(p::FilePattern, t0, t1; refresh=false, version="*", kw...) :: Vector{String}

URLs of the files over `[t0, t1)`. Steps with no published file are dropped
rather than an error, since a gap in an archive is normal.

Keywords fill `p`'s placeholders; `version` defaults to the `*` wildcard, picking the highest
listed. `refresh=true` bypasses memoized directory listings.
"""
function remotefiles(p::FilePattern, t0, t1; refresh=false, ntasks=8, version="*", kw...)
    q = p(; version, kw...)
    resolved = asyncmap(t -> resolve_url(q(t); refresh), _stepstarts(p, t0, t1); ntasks)
    return String[u for u in resolved if !isnothing(u)]
end

function available(p::FilePattern, t0, t1; refresh=false, ntasks=8, version="*", kw...)
    q = p(; version, kw...)
    steps = _stepstarts(p, t0, t1)
    resolved = asyncmap(t -> resolve_url(q(t); refresh), steps; ntasks)
    return DateTime[t for (t, u) in zip(steps, resolved) if !isnothing(u)]
end

_time(t::AbstractString) = parse_datetime(t)
_time(t::Date) = DateTime(t)
_time(t) = t

# Starts of the cadence-aligned file bins covering `[t0, t1)`.
function _stepstarts(p::FilePattern, t0, t1)
    a, b = _time(t0), _time(t1)
    a < b || throw(ArgumentError("t1 must be after t0"))
    return floor(a, p.cadence):p.cadence:(ceil(b, p.cadence)-p.cadence)
end

_hint() = "`available(ds, t0, t1)` lists the steps this archive does publish."

@noinline function _no_files(p::FilePattern, t0, t1; version="*")
    n = length(_stepstarts(p, t0, t1))
    throw(ArgumentError("""
        no files published over $t0 .. $t1 ($n steps of $(p.cadence)) for
          $(_pattern(p(; version)))
        $(_hint())"""))
end

const _LISTINGS = Dict{String,Task}()
const _LISTINGS_LOCK = ReentrantLock()

# libcurl reports success as status 0 for schemes carrying no numeric status, such as file://.
_ok(resp) = resp isa Downloads.Response && (iszero(resp.status) || 200 <= resp.status < 300)

# File names in a remote directory
function _listing(url)
    io = IOBuffer()
    resp = request(url; output=io, throw=false)
    _ok(resp) && return _index_names(String(take!(io)))
    @warn "Remote directory not listed" url reason = resp isa Downloads.Response ? "HTTP $(resp.status)" : resp.message
    return nothing
end

function tryreaddir(path; refresh=false)::Union{Nothing,Vector{String}}
    url = endswith(path, '/') ? path : path * "/"
    task = lock(_LISTINGS_LOCK) do
        refresh || !haskey(_LISTINGS, url) ? (_LISTINGS[url] = Threads.@spawn _listing(url)) : _LISTINGS[url]
    end
    return fetch(task)
end

# Catch href attributes; ignore parent links, subdirectories and absolute site navigation.
function _index_names(html)
    names = String[m.captures[1] for m in eachmatch(r"<a href=\"([^\"]+)\"", html)]
    return filter!(
        n -> !startswith(n, '/') && !startswith(n, '?') && !endswith(n, '/') && !occursin("://", n),
        names
    )
end

# `*` stands for a version field, so it matches digits and the separators archives write between
# them -- not `[^/]*`, which would let a sibling like `…_v01_beta.cdf` answer for `…_v*.cdf`.
_name_regex(name) = Regex("^" * join((_escape(s) for s in split(name, '*')), "([0-9][0-9._-]*)") * "\\z")
_escape(s) = replace(s, r"[\\^$.|?*+()\[\]{}]" => s"\\\0")

# Ordering on the version's integer fields so `v1.1.10` outranks `v1.1.2`.
_numkey(v) = Int[parse(Int, m.match) for m in eachmatch(r"\d+", v)]

function local_path(uri, dir)
    s = string(uri)
    i = findfirst("//", s)
    isnothing(i) || (s = s[(last(i)+1):end])
    return joinpath(dir, split(s, '/'; keepempty=false)...)
end

function _download_atomic(uri, path)
    dir = dirname(path)
    mkpath(dir)
    return mktemp(dir) do tmp, io
        close(io)
        Downloads.download(uri, tmp)
        mv(tmp, path; force=true)
    end
end
