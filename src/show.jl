_isdefault(v) = false
_isdefault(v::AbstractDict) = isempty(v)
_isdefault(v::Tuple) = isempty(v)

_typename(x) = nameof(typeof(x))
_typename(x::AbstractArray{T,N}) where {T,N} = string(nameof(typeof(x)), "{$T, $N}")
_print_type(io, x) = print(io, " (", _typename(x), "): ")

_println_value(io, value, prefix="  ") = (println(io); print(io, prefix, "  ", value))
_println_value(io, value::AbstractArray{<:Number}, prefix="  ") = (println(io); print(io, prefix, "  ", value))
function _println_value(io, value::Union{AbstractVector,AbstractDict,Tuple}, prefix="  ")
    for (k, v) in pairs(value)
        println(io)
        print(io, prefix, "  ", k, ": ", v)
    end
end

@generated function Base.show(io::IO, ::MIME"text/plain", p::T) where {T<:AbstractModel}
    fs = setdiff(fieldnames(T), (:name, :format))
    exs = map(fs) do f
        sf = QuoteNode(f)
        title = titlecase(String(f))
        quote
            v = getfield(p, $sf)
            if !_isdefault(v)
                println(io)
                print(io, "  ", $title)
                _print_type(io, v)
                _println_value(io, v)
            end
        end
    end
    return quote
        printstyled(io, nameof(T), ": "; bold=true)
        printstyled(io, name(p), color=:yellow)
        $(exs...)
    end
end
