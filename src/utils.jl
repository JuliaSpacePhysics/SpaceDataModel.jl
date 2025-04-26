"""
    @get(collection, key, default)

Short-circuiting version of [`get`](@ref). See also [`@something`](@ref).
"""
macro get(collection, key, default)
    val = gensym()
    quote
        $val = get($(esc(collection)), $(esc(key)), nothing)
        !isnothing($val) ? $val : $(esc(default))
    end
end

_getfield(v::T, name::Symbol, d=nothing) where {T} = hasfield(T, name) ? getfield(v, name) : d
_getfield(v, names, d=nothing) = something(_getfield.(Ref(v), names)..., d) # no runtime cost

function _insert!(d::AbstractDict{K}, kw) where {K}
    for (k, v) in kw
        d[K(k)] = v
    end
    return d
end

compat_dict(K::Type, m) = _insert!(Dict{K,Any}(), m)
compat_dict(K::Type, m, kw) = _insert!(compat_dict(K, m), kw)
compat_dict(m, kw) = compat_dict(String, m, kw)

symbolify(d::Dict) = Dict{Symbol,Any}(Symbol(k) => v for (k, v) in d)

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
_println_type(io, ::T) where {T} = println(io, " (", T, "):")
_println_value(io, value, prefix="  ") = println(io, prefix, "  ", value)
_println_value(io, value::AbstractVector{<:Number}, prefix="  ") = println(io, prefix, ": ", value)
function _println_value(io, value::Union{AbstractVector,AbstractDict,Tuple}, prefix="  ")
    for (k, v) in pairs(value)
        println(io, prefix, "  ", k, ": ", v)
    end
end
