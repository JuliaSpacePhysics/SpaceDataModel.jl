_datasets(reg) = values(reg.datasets)

"""Selector names any of the registry's datasets carries."""
function vocabulary(reg::Registry)
    names = Symbol[]
    for ds in _datasets(reg), k in keys(selectors(ds))
        k in names || push!(names, k)
    end
    return names
end

_matches(ds, k, v) = (d = get(selectors(ds), k, nothing); !isnothing(d) && _member(d, string(v)))

_supplied_match(ds, sel) = all(_matches(ds, k, v) for (k, v) in sel)

# A default constrains only datasets that carry it and only when not overridden.
_defaults_match(ds, defaults, sel) =
    all(!haskey(selectors(ds), k) || _matches(ds, k, v) for (k, v) in defaults if !haskey(sel, k))

_check_vocabulary(reg, sel) =
    for k in keys(sel)
        any(ds -> haskey(selectors(ds), k), _datasets(reg)) || _unknown_selectors(reg, keys(sel))
    end

"""
    filter(reg::Registry; selectors...)

The rows of `reg` every supplied selector matches, each with the matched columns pinned.
"""
Base.filter(reg::Registry; kw...) = filter(reg, Selectors(kw))

function Base.filter(reg::Registry, sel::Selectors)
    _check_vocabulary(reg, sel)
    rows = [pin(ds, sel) for ds in _datasets(reg) if _supplied_match(ds, sel)]
    return setproperties(reg, (; datasets=rows, defaults=merge(reg.defaults, sel)))
end

"""
    select(reg; selectors...)

The *one* dataset of `reg` every supplied selector matches, with omitted selectors filled from
`reg.defaults` where the dataset carries them.
"""
select(reg::Registry; kw...) = select(reg, Selectors(kw))

function select(reg::Registry, sel::Selectors)
    _check_vocabulary(reg, sel)
    # Lazy so the happy path neither allocates a candidate list nor walks past the second match.
    cands = Iterators.filter(ds -> _supplied_match(ds, sel) && _defaults_match(ds, reg.defaults, sel), _datasets(reg))
    hit = iterate(cands)
    (isnothing(hit) || !isnothing(iterate(cands, hit[2]))) && _no_single_dataset(reg, sel)
    return pin(hit[1], merge(reg.defaults, sel); complete=true)
end

_pinned(d) = d isa String

function _pin(ds, k, d, values, complete)
    _pinned(d) && return k => d
    haskey(values, k) || (complete && _unpinnable(ds, k, d); return k => d)
    v = string(values[k])
    _member(d, v) || throw(ArgumentError("$(name(ds)): $v not in domain of $k, $(_show_domain(d))"))
    return k => v
end

"""
    pin(ds, values; complete=false)

Pin the open domains of `ds` named in `values` and rebuild its name and source with the
pinned spellings; untouched domains stay open unless `complete=true`, which demands every
one resolves.
"""
function pin(ds, values; complete::Bool=false)
    sel = selectors(ds)
    all(p -> _pinned(p.second), sel) && return ds
    pinned = Selectors(Pair{Symbol,Domain}[_pin(ds, k, d, values, complete) for (k, d) in sel])
    fills = Selectors(Pair{Symbol,Domain}[p for p in pinned if _pinned(p.second)])
    return setproperties(ds, (; name=_format(ds.name, fills), selectors=pinned, source=bind(ds.source, fills)))
end

@noinline _unpinnable(ds, k, d) =
    throw(ArgumentError("$(name(ds)): selector $k must be given; domain $(_show_domain(d))"))

@noinline function _unknown_selectors(reg, supplied)
    vocab = vocabulary(reg)
    unknown = setdiff(supplied, vocab)
    label = length(unknown) == 1 ? "selector" : "selectors"
    throw(ArgumentError("$(reg.name): unknown $label $(join(unknown, ", ")); known: $(join(vocab, ", "))"))
end

@noinline function _no_single_dataset(reg, sel)
    cands = [ds for ds in _datasets(reg) if _supplied_match(ds, sel) && _defaults_match(ds, reg.defaults, sel)]
    listed = isempty(cands) ? _datasets(reg) : cands
    n = isempty(cands) ? "no dataset" : "$(length(cands)) datasets"
    throw(ArgumentError("""
        $(reg.name): $n for $(sel), default selectors $(reg.defaults).
        Available:
        $(join(("  $(name(ds)): $(selectors(ds))" for ds in listed), "\n"))"""))
end
