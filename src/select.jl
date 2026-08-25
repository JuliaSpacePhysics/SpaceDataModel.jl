_members(d) = (d,)
_members(d::Union{Tuple,AbstractArray,AbstractSet}) = d

_datasets(reg) = values(reg.datasets)

"""Selector names any of the registry's datasets carries."""
function vocabulary(reg::Registry)
    names = Symbol[]
    for ds in _datasets(reg), key in keys(selectors(ds))
        k = key::Symbol
        k in names || push!(names, k)
    end
    return names
end

# Domain membership is `==`; a Symbol answers for its String spelling.
_eq(m, v) = m == v
_eq(m::AbstractString, v::Symbol) = m == String(v)

_member(::Type{Any}, ::Any) = true
_member(d, v) = any(m -> _eq(m, v), _members(d))

_matches(ds, k, v) = (sel=selectors(ds); haskey(sel, k) && _member(sel[k], v))

_supplied_match(ds, kw) = all(_matches(ds, k, v) for (k, v) in pairs(kw))

# A default constrains only datasets that carry it and only when not overridden.
_defaults_match(ds, defaults, kw) =
    all(!haskey(selectors(ds), k) || _matches(ds, k, v) for (k, v) in pairs(defaults) if !haskey(kw, k))

_check_vocabulary(reg, kw) = begin
    vocab = vocabulary(reg)
    unknown = setdiff(keys(kw), vocab)
    isempty(unknown) || _unknown_selectors(reg, unknown, vocab)
end

"""
    filter(reg::Registry; selectors...)

The rows of `reg` every supplied selector matches, each with the matched columns pinned.
"""
function Base.filter(reg::Registry; kw...)
    _check_vocabulary(reg, kw)
    rows = [pin(ds, kw) for ds in _datasets(reg) if _supplied_match(ds, kw)]
    return setproperties(reg, (; datasets=rows, defaults=merge(reg.defaults, kw)))
end

"""
    select(reg; selectors...)

The *one* dataset of `reg` every supplied selector matches, with omitted selectors filled from
`reg.defaults` where the dataset carries them.
"""
function select(reg::Registry; kw...)
    _check_vocabulary(reg, kw)
    cands = filter(ds -> _supplied_match(ds, kw) && _defaults_match(ds, reg.defaults, kw), _datasets(reg))
    length(cands) == 1 || _no_single_dataset(reg, kw, cands)
    return pin(only(cands), merge(reg.defaults, kw); complete=true)
end

_pinned(d) = d !== Any && length(_members(d)) == 1

_pin(::Type{Any}, v) = v
_pin(d, v) = _members(d)[findfirst(m -> _eq(m, v), _members(d))]

"""
    pin(ds, values; complete=false)

Pin the open domains of `ds` named in `values` and rebuild its name and source with the
pinned spellings; untouched domains stay open unless `complete=true`, which demands every
one resolves.
"""
function pin(ds, values; complete::Bool=false)
    sel = selectors(ds)
    all(_pinned, sel) && return ds
    pinned = map(keys(sel), sel) do k, d
        _pinned(d) && return only(_members(d))
        haskey(values, k) && return _pin(d, values[k])
        complete && throw(ArgumentError("$(name(ds)): selector $k must be given; domain $(_show_domain(d))"))
        return d
    end
    nt = NamedTuple{keys(sel)}(pinned)
    fills = NamedTuple(k => v for (k, v) in pairs(nt) if _pinned(sel[k]) || haskey(values, k))
    return setproperties(ds, (; name=_format(ds.name; fills...), selectors=nt, source=bind(ds.source; fills...)))
end

_show_domain(d) = d === Any ? "*" : _pinned(d) ? string(only(_members(d))) : "{" * join(_members(d), ",") * "}"
_show_selectors(nt) = join(("$k=$(_show_domain(v))" for (k, v) in pairs(nt)), " ")

@noinline function _unknown_selectors(reg, unknown, vocab)
    label = length(unknown) == 1 ? "selector" : "selectors"
    throw(ArgumentError("$(reg.name): unknown $label $(join(unknown, ", ")); known: $(join(vocab, ", "))"))
end

@noinline function _no_single_dataset(reg, kw, cands)
    listed = isempty(cands) ? _datasets(reg) : cands
    n = isempty(cands) ? "no dataset" : "$(length(cands)) datasets"
    throw(ArgumentError("""
        $(reg.name): $n for $(_show_selectors(kw)) (defaults $(_show_selectors(reg.defaults))).
        Available:
        $(join(("  $(name(ds)): $(_show_selectors(selectors(ds)))" for ds in listed), "\n"))"""))
end
