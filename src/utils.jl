eqfields(a::T, b::T, eq = ==) where {T} = all(i -> eq(getfield(a, i), getfield(b, i)), 1:nfields(a))
eqfields(a, b, eq = ==) = false
hashfields(x, h::UInt) = foldl((h, i) -> hash(getfield(x, i), h), 1:nfields(x); init = hash(typeof(x), h))

macro getproperty(value, names::Expr, default = nothing)
    v = esc(value)
    tests = Expr[]
    for name in names.args
        push!(tests, :(hasproperty($v, $name) && (return getproperty($v, $name))))
    end
    return quote
        $(tests...)
        return $(esc(default))
    end
end

print_name(io::IO, var) = printstyled(io, name(var); color = 37)

# like merge to avoid privacy issues
# https://github.com/rafaqz/DimensionalData.jl/issues/1142
_merge(a, b...) = merge(a, b...)
