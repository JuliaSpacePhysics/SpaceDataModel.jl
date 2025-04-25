"""
    abbr(p::Project; lowercase = true)

Get the abbreviation (abbr) of a project.
"""
function abbr(p::Project; lowercase=false)
    ab = @get(p, "abbreviation", name(p))
    return lowercase ? Base.lowercase(ab) : ab
end

struct Extended{F,T} <: Function
    f::F
    left::T
    right::T
end

Extended(f, margin) = Extended(f, margin, margin)

(t::Extended)(data, t0, t1) = t.f(data, t0 - t.left, t1 + t.right)

extend(p::Product, l, r=l) = @set p.transformation = Extended(func(p), l, r)