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
    return _mask_invalid!(similar(x, _float(eltype(x))), x, fillval, validmin, validmax, depend_1_dimnum(x))
end

"""
    mask_invalid!(A; dims = nothing, fillval = nothing, validmin = nothing, validmax = nothing)

Replace elements of `A` equal to `fillval` or outside `[validmin, validmax]` by `NaN` and return the result.

`fillval` is compared with `isequal` after rounding to `eltype(A)`, so a `NaN` fill value matches.
A vector `fillval` or bound holds one value per component along dimension `dims`. Float arrays are
overwritten in place; integer arrays are converted to the smallest float type that represents them exactly. Arrays of non-`Real` elements (epochs, strings)
have no `NaN` and are returned unchanged.
"""
function mask_invalid!(A::AbstractArray; dims::Union{Integer, Nothing} = nothing, fillval = nothing, validmin = nothing, validmax = nothing)
    eltype(A) <: Real || return A
    F = _float(eltype(A))
    B = eltype(A) === F ? A : similar(A, F)
    return _mask_invalid!(B, A, fillval, validmin, validmax, dims)
end

_bound(x, _, _) = x
function _bound(v::AbstractVector, A, dims)
    length(v) == 1 && return only(v)
    isnothing(dims) && throw(ArgumentError("a bound with $(length(v)) components needs `dims`"))
    return reshape(v, ntuple(d -> d == dims ? length(v) : 1, ndims(A)))
end

# A Float64 FILLVAL does not `isequal` the same value stored as Float32 data; round it to the data's type.
_fill(v::AbstractFloat, ::Type{T}) where {T <: AbstractFloat} = T(v)
_fill(v::AbstractVector, ::Type{T}) where {T} = _fill.(v, T)
_fill(v, _) = v

_below(x, lo) = x < lo
_below(x, ::Nothing) = false
_above(x, hi) = x > hi
_above(x, ::Nothing) = false
# `<`/`>` are false for NaN
isinvalid(x, fillval, lo, hi) = isequal(x, fillval) | _below(x, lo) | _above(x, hi)

_float(::Type{<:Union{Int8, UInt8, Int16, UInt16}}) = Float32
_float(::Type{T}) where {T} = float(T)

_mask_invalid!(B, A, fillval, validmin, validmax, dims) = __mask_invalid!(
    B, A, _bound(_fill(fillval, eltype(A)), A, dims), _bound(validmin, A, dims), _bound(validmax, A, dims)
)

# Function barrier: fill values and bounds read from metadata are usually typed `Any`.
function __mask_invalid!(B::AbstractArray{F}, A, fillval, lo, hi) where {F}
    return @. B = ifelse(isinvalid(A, fillval, lo, hi), F(NaN), F(A))
end
