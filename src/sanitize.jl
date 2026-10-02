"""
    sanitize(x)

Values of `x` with fill and out-of-range values replaced by `NaN`, per the `fill_value`, `valid_min`
and `valid_max` of its schema (`get_schema(x)`); `x` itself when it has none of them or non-`Real` elements.

Metadata survives arithmetic and unit conversion, so derived data carrying its source's bounds is masked
by them. Types whose values are not in memory (e.g. file variables) extend it to read and mask at once.
"""
sanitize(x) = x
function sanitize(x::AbstractArray)
    eltype(x) <: Real || return x
    s = get_schema(x)(x)
    fillval, validmin, validmax = s[:fill_value], s[:valid_min], s[:valid_max]
    all(isnothing, (fillval, validmin, validmax)) && return x
    A = eltype(x) === _float(eltype(x)) ? copy(x) : x
    return mask_invalid!(A; fillval, validmin, validmax, dims = depend_1_dimnum(x))
end

"""
    mask_invalid!(A; dims, fillval = nothing, validmin = nothing, validmax = nothing)

Replace elements of `A` equal to `fillval` or outside `[validmin, validmax]` by `NaN` and return the result.

`fillval` is compared with `isequal`, so a `NaN` fill value matches. A vector `fillval` or bound holds
one value per component along dimension `dims`. Float arrays are overwritten in place; integer arrays are converted to
the smallest float type that represents them exactly. Arrays of non-`Real` elements (epochs, strings)
have no `NaN` and are returned unchanged.
"""
function mask_invalid!(A::AbstractArray; dims::Integer, fillval = nothing, validmin = nothing, validmax = nothing)
    eltype(A) <: Real || return A
    fillval = _bound(fillval, A, dims)
    lo = _bound(validmin, A, dims)
    hi = _bound(validmax, A, dims)
    return _mask_invalid!(_float(eltype(A)), A, fillval, lo, hi)
end

_bound(x, _, _) = x
_bound(v::AbstractVector, A, dims) =
    length(v) == 1 ? only(v) : reshape(v, ntuple(d -> d == dims ? length(v) : 1, ndims(A)))

_below(x, lo) = x < lo
_below(x, ::Nothing) = false
_above(x, hi) = x > hi
_above(x, ::Nothing) = false
# `<`/`>` are false for NaN
isinvalid(x, fillval, lo, hi) = isequal(x, fillval) | _below(x, lo) | _above(x, hi)

_float(::Type{<:Union{Int8, UInt8, Int16, UInt16}}) = Float32
_float(::Type{T}) where {T} = float(T)

# Function barrier: fill values and bounds read from metadata are usually typed `Any`.
function _mask_invalid!(::Type{F}, A, fillval, lo, hi) where {F}
    B = eltype(A) === F ? A : similar(A, F)
    return @. B = ifelse(isinvalid(A, fillval, lo, hi), F(NaN), F(A))
end
