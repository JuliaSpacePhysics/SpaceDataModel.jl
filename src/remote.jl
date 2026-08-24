using Dates
using Downloads: Downloads, request

datadir() = get(ENV, "SPACE_DATA_DIR", joinpath(homedir(), ".cache", "spacedata"))

"""
    localize(url; dir=datadir(), update=false) -> String
    localize(urls; ntasks=4, kw...) -> Vector{String}

Return a local path for each URL, downloading files missing from the cache.

Set the `SPACE_DATA_DIR` environment variable to override the default cache directory.

`update` is `false`, `true`, or a `Period` (refetch if the local copy is older).
"""
localize(urls::AbstractVector; ntasks=4, kw...) =
    asyncmap(url -> localize(url; kw...), urls; ntasks)

function localize(url; dir=datadir(), update=false)
    _stale(_, update::Bool) = update
    _stale(path, age::Period) = now() - unix2datetime(mtime(path)) > age

    path = local_path(url, dir)
    return isfile(path) && !_stale(path, update) ? path : _download_atomic(url, path)
end

const VERSION_FIELD = "{version}"

"""
    resolve_url(url; refresh=false)

Concrete URL for `url`, where $VERSION_FIELD is replaced with the highest version found in the directory.

The field matches any width and any separator (e.g., `v03`, `v03.06`, `v03_01`, `v1.1.10`).
"""
function resolve_url(url; refresh=false)
    occursin(VERSION_FIELD, url) || return url
    name = basename(url)
    dir = url[1:(end-length(name))]
    i = findfirst(VERSION_FIELD, name)
    pre, post = name[1:prevind(name, first(i))], name[nextind(name, last(i)):end]
    names = tryreaddir(dir; refresh)
    isnothing(names) && return nothing
    best, bestkey = nothing, nothing
    for n in names
        v = _version_field(n, pre, post)
        isnothing(v) && continue
        key = _numkey(v)
        if isnothing(bestkey) || key > bestkey
            best, bestkey = n, key
        end
    end
    return isnothing(best) ? nothing : dir * best
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

function _version_field(name, pre, post)
    startswith(name, pre) || return nothing
    v = chopprefix(name, pre)
    endswith(v, post) || return nothing
    v = chopsuffix(v, post)
    (isempty(v) || !isdigit(first(v))) && return nothing
    all(c -> isdigit(c) || c == '.' || c == '_' || c == '-', v) || return nothing
    return v
end

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
