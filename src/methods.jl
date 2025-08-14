struct Extended{F,T} <: Function
    f::F
    left::T
    right::T
end

Extended(f, margin) = Extended(f, margin, margin)

(t::Extended)(data, t0, t1) = t.f(data, t0 - t.left, t1 + t.right)

extend(p::Product, l, r=l) = @set p.transformation = Extended(func(p), l, r)