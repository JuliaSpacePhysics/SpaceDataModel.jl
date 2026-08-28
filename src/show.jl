const _Model = Union{Registry,Dataset,Product}

Base.show(io::IO, p::Union{Registry,Product}) = print(io, name(p))
_show_ctor(io, x, vals...) = (print(io, nameof(typeof(x)), '('); join(io, vals, ", "); print(io, ')'))

Base.show(io::IO, a::Archive) = _show_ctor(io, a, a.pattern, a.reader)
function Base.show(io::IO, t::Transformed)
    _isdefault(t.metadata) ? _show_ctor(io, t, t.f, t.source) :
    _show_ctor(io, t, t.f, t.source, t.metadata)
end

_isdefault(v) = false
_isdefault(::NoMetadata) = true
_isdefault(v::Union{AbstractDict,Tuple,NamedTuple}) = isempty(v)

_println_value(io, value, prefix="  ") = (println(io); print(io, prefix, "  ", value))
_println_value(io, value::AbstractArray{<:Number}, prefix="  ") = (println(io); print(io, prefix, "  ", value))
function _println_value(io, value::Union{AbstractVector,AbstractDict,Tuple,NamedTuple}, prefix="  ")
    for (k, v) in pairs(value)
        println(io)
        print(io, prefix, "  ", k, ": ", v)
    end
end

@generated function Base.show(io::IO, ::MIME"text/plain", p::T) where {T<:_Model}
    fs = setdiff(fieldnames(T), (:name,))
    exs = map(fs) do f
        sf = QuoteNode(f)
        title = titlecase(String(f))
        quote
            v = getfield(p, $sf)
            if !_isdefault(v)
                println(io)
                print(io, "  ", $title, ": ")
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
