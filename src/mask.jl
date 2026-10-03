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
    fill, lo, hi = _bounds(eltype(B), fillval, validmin, validmax)
    isnothing(dims) && any(v -> length(v) > 1, (fill, lo, hi)) &&
        throw(ArgumentError("a bound with several components needs `dims`"))
    return _mask_invalid!(B, A, fill, lo, hi, something(dims, 1))
end

_schema_value(x, key) = get_schema(x)(x)[key]

# Checks as `Vector{F}` (one value, or one per component), an absent one as a NaN fill or ∓Inf bound,
# so the kernel compiles once per element type whatever types the metadata holds. Rounding a fill
# value to `F` also matches a Float64 FILLVAL against Float32 data.
_bounds(::Type{F}, fillval, validmin, validmax) where {F} =
    (_vec(F, fillval, F(NaN)), _vec(F, validmin, F(-Inf)), _vec(F, validmax, F(Inf)))
_vec(::Type{F}, ::Nothing, default) where {F} = F[default]
_vec(::Type{F}, v::AbstractVector, _) where {F} = convert(Vector{F}, v)
_vec(::Type{F}, x, _) where {F} = F[x]

# Like xarray's CF decoding: Float16 loses sums (max 65504), so small integers take Float32.
_float(::Type{<:Union{Int8, UInt8, Int16, UInt16, Float16}}) = Float32
_float(::Type{T}) where {T} = float(T)

_at(v, c) = length(v) == 1 ? @inbounds(v[1]) : v[c]

function _mask_invalid!(B::AbstractArray{F}, A, fill::Vector{F}, lo::Vector{F}, hi::Vector{F}, dims::Int) where {F}
    if length(fill) == length(lo) == length(hi) == 1
        _mask_kernel!(vec(B), vec(A), only(fill), only(lo), only(hi))
    else
        shape = (prod(i -> size(A, i), 1:(dims - 1); init = 1), size(A, dims), prod(i -> size(A, i), (dims + 1):ndims(A); init = 1))
        _mask_kernel!(reshape(B, shape), reshape(A, shape), fill, lo, hi)
    end
    return B
end

# Vectors and three dimensions (before, component, after) whatever `ndims(A)`, so this compiles
# once per element-type pair. `<`/`>` are false for NaN, and a NaN fill matches NaN data.
_invalid(x, f, l, h) = isequal(x, f) | (x < l) | (x > h)

function _mask_kernel!(B::AbstractVector{F}, A::AbstractVector, f::F, l::F, h::F) where {F}
    @inbounds @simd for i in eachindex(B, A)
        x = F(A[i])
        B[i] = ifelse(_invalid(x, f, l, h), F(NaN), x)
    end
    return B
end

function _mask_kernel!(B::AbstractArray{F, 3}, A::AbstractArray{<:Any, 3}, fill, lo, hi) where {F}
    for v in (fill, lo, hi)
        length(v) == 1 || checkbounds(v, axes(A, 2))
    end
    @inbounds for k in axes(A, 3), c in axes(A, 2), i in axes(A, 1)
        x = F(A[i, c, k])
        B[i, c, k] = ifelse(_invalid(x, _at(fill, c), _at(lo, c), _at(hi, c)), F(NaN), x)
    end
    return B
end
