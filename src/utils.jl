"""
    @get(collection, key, default)

Short-circuiting version of [`get`](@ref). See also [`@something`](@ref).
"""
macro get(collection, key, default=nothing)
    val = gensym()
    quote
        $val = get($(esc(collection)), $(esc(key)), nothing)
        !isnothing($val) ? $val : $(esc(default))
    end
end

macro prior_get(c, keys, default=nothing)
    tests = map(keys.args) do k
        :(haskey($(esc(c)), $(esc(k))) && (return $(esc(c))[$(esc(k))]))
    end
    return quote
        $(tests...)
        return $(esc(default))
    end
end

function prior_get(c, keys, default=nothing)
    for k in keys
        haskey(c, k) && return c[k]
    end
    return default
end

"""Short-circuiting version of [`_getfield`](@ref)."""
macro getfield(value, name, default=nothing)
    :(hasfield(typeof($(esc(value))), $name) ? getfield($(esc(value)), $name) : $(esc(default)))
end

macro getfield(value, names::Expr, default=nothing)
    tests = map(names.args) do name
        :(hasfield(typeof($(esc(value))), $name) && (return getfield($(esc(value)), $name)))
    end
    quote
        $(tests...)
        return $(esc(default))
    end
end

"""
    _getfield(v, name, default)

Return the field from a composite `v` for the given `name`, or the given `default` if no field is present.

See also: `getfield`.
"""
_getfield(v, name::Symbol, default=nothing) = hasfield(typeof(v), name) ? getfield(v, name) : default
_getfield(v, names, default=Some(nothing)) = something(_getfield.(Ref(v), names)..., default) # no runtime cost

function _insert!(d::AbstractDict{K}, kw) where {K}
    for (k, v) in kw
        d[K(k)] = v
    end
    return d
end

# https://github.com/JuliaLang/julia/issues/54454
_nth(itr, n) = begin
    y = iterate(Base.Iterators.drop(itr, n-1))
    isnothing(y) ? throw(BoundsError(itr, n)) : first(y)
end

compat_dict(K::Type, m) = _insert!(Dict{K,Any}(), m)
compat_dict(K::Type, m, kw) = _insert!(compat_dict(K, m), kw)
compat_dict(m, kw) = compat_dict(String, m, kw)

function format_pattern(pattern; kwargs...)
    pairs = ("{$k}" => v for (k, v) in kwargs)
    return replace(pattern, pairs...)
end

function rename!(d::Dict, old_key, new_key)
    data = pop!(d, old_key, nothing)

    if !isnothing(data)
        d[new_key] = data
    end
end

function rename!(d::Dict, old_keys::Union{Tuple,Vector}, new_key)
    for old_key in old_keys
        rename!(d, old_key, new_key)
    end
end

function set!(d::Dict, args::Pair...; kwargs...)
    foreach(args) do (k, v)
        d[k] = v
    end
    merge!(d, kwargs)
end

function set(d::Dict, args::Pair...; kwargs...)
    return merge(d, Dict(args...), kwargs)
end

# https://github.com/rafaqz/DimensionalData.jl/blob/main/src/Dimensions/show.jl#L5
function colors(i)
    colors = [209, 32, 81, 204, 249, 166, 37]
    c = rem(i - 1, length(colors)) + 1
    colors[c]
end

print_name(io::IO, var) = printstyled(io, name(var); color=colors(7))
