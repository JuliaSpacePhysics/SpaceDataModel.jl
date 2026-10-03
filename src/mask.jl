"""
    mask_invalid(x; fillval, validmin, validmax, dims)

Copy of `x` with elements equal to `fillval` or outside `[validmin, validmax]` replaced by `NaN`.

Each keyword defaults to the schema value of `x` (`get_schema(x)`: `fill_value`, `valid_min`,
`valid_max`); `nothing` disables that check. A vector `fillval` or bound holds one value per component
along dimension `dims`, by default the `depend_1` dimension.

Metadata describes the values as stored: mask before arithmetic or unit conversion, which keep the
metadata but not its meaning. Storage types decode on read and need no call.

Integers become the smallest float type that represents them exactly. Arrays of non-`Real` elements
(epochs, strings) have no `NaN` and are returned unchanged.
"""
function mask_invalid(x; kw...)
    eltype(x) <: Real || return x
    return mask_invalid!(similar(x, _float(eltype(x))), x; kw...)
end

"""
    mask_invalid!(A; kw...)
    mask_invalid!(B, A; kw...)

[`mask_invalid`](@ref) writing into `B`, or into `A` when its elements are already floats; use the
returned array, which is a new one for integer `A`.
"""
function mask_invalid!(A::AbstractArray; kw...)
    eltype(A) <: Real || return A
    F = _float(eltype(A))
    return mask_invalid!(eltype(A) === F ? A : similar(A, F), A; kw...)
end

function mask_invalid!(
        B::AbstractArray, A::AbstractArray;
        fillval = _schema_value(A, :fill_value), validmin = _schema_value(A, :valid_min),
        validmax = _schema_value(A, :valid_max), dims = depend_1_dimnum(A)
    )
    return _mask_invalid!(
        B, A, _bound(_fill(fillval, eltype(A)), A, dims), _bound(validmin, A, dims), _bound(validmax, A, dims)
    )
end

_schema_value(x, key) = get_schema(x)(x)[key]

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

# Like xarray's CF decoding: Float16 loses sums (max 65504), so small integers take Float32.
_float(::Type{<:Union{Int8, UInt8, Int16, UInt16, Float16}}) = Float32
_float(::Type{T}) where {T} = float(T)

# Function barrier: fill values and bounds read from metadata are usually typed `Any`.
function _mask_invalid!(B::AbstractArray{F}, A, fillval, lo, hi) where {F}
    return @. B = ifelse(isinvalid(A, fillval, lo, hi), F(NaN), F(A))
end
