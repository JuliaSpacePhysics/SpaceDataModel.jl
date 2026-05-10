macro getproperty(value, names::Expr, default = nothing)
    tests = map(names.args) do name
        :(hasproperty($(esc(value)), $name) && (return getproperty($(esc(value)), $name)))
    end
    return quote
        $(tests...)
        return $(esc(default))
    end
end

# https://github.com/JuliaLang/julia/issues/54454
_nth(itr, n) = begin
    y = iterate(Base.Iterators.drop(itr, n - 1))
    isnothing(y) ? throw(BoundsError(itr, n)) : first(y)
end

function format_pattern(pattern; kwargs...)
    pairs = ("{$k}" => v for (k, v) in kwargs)
    return replace(pattern, pairs...)
end

# https://github.com/rafaqz/DimensionalData.jl/blob/main/src/Dimensions/show.jl#L5
function colors(i)
    colors = [209, 32, 81, 204, 249, 166, 37]
    c = rem(i - 1, length(colors)) + 1
    return colors[c]
end

print_name(io::IO, var) = printstyled(io, name(var); color = colors(7))

# like merge to avoid privacy issues
# https://github.com/rafaqz/DimensionalData.jl/issues/1142
_merge(a, b...) = merge(a, b...)

function set!(d::AbstractDict, args::Pair...; kw...)
    for (k, v) in args
        d[k] = v
    end
    return merge!(d, kw)
end
set!(d::AbstractDict, dict::AbstractDict; kw...) = merge!(d, dict, kw)
