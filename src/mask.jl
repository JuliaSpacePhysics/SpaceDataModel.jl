"""
    ValidityChecks(T, fillval, validmin, validmax)
    ValidityChecks(x)

Fill value and valid range `[validmin, validmax]` of data with `Real` element type `T`. Each is a value, a vector of one value per component, or
`nothing` to disable it. For `x`, they are its schema values (`get_schema(x)`) and `T = eltype(x)`; a vector whose length
is not the number of components along `depend_1` acts as one value if its values are equal, and is dropped otherwise.
"""
struct ValidityChecks{C}
    fillval::Vector{C}
    validmin::Vector{C}
    validmax::Vector{C}
end

# Checks compare in the data's float type `C`: rounding a fill value to it matches a Float64 FILLVAL
# against Float32 data. Absent checks are a never-matching fill or unreachable bounds rather than
# `nothing`, keeping one type, and one set of compiled kernels, per `C`.
function ValidityChecks(::Type{T}, fillval, validmin, validmax) where {T <: Real}
    C = _float(T)
    return ValidityChecks{C}(_vec(C, fillval, C(NaN)), _vec(C, validmin, typemin(C)), _vec(C, validmax, typemax(C)))
end

function ValidityChecks(x)
    s = get_schema(x)(x)
    d = depend_1_dimnum(x)
    n = isnothing(d) ? 1 : size(x, d)
    return ValidityChecks(eltype(x), _fit(s[:fillval], n), _fit(s[:validmin], n), _fit(s[:validmax], n))
end

# Some CDAWeb masters give a length matching no dimension
_fit(v, n) = v isa AbstractVector && length(v) > 1 && length(v) != n ? (allequal(v) ? first(v) : nothing) : v

_fields(c::ValidityChecks) = (c.fillval, c.validmin, c.validmax)
_ncomponents(c::ValidityChecks) = max(length(c.fillval), length(c.validmin), length(c.validmax))
Base.getindex(c::ValidityChecks, i) = ValidityChecks(map(v -> length(v) == 1 ? v : v[i isa Integer ? (i:i) : i], _fields(c))...)
Base.isequal(a::ValidityChecks, b::ValidityChecks) = isequal(_fields(a), _fields(b))
Base.hash(c::ValidityChecks, h::UInt) = hash(_fields(c), hash(ValidityChecks, h))

"""
    mask_invalid(A, checks = ValidityChecks(A), dims = nothing)

Copy of `A` with elements failing `checks` replaced by `NaN`. Checks with several components apply along dimensions `dims`, an integer or a range;
by default `depend_1`, the first non-time dimension.

Mask before arithmetic or unit conversion: metadata describes stored values.

Int8/UInt8, Int16/UInt16 and Float16 promote to Float32, wider integers to Float64, so Int64/UInt64 beyond 2^53
compare after rounding. Without `checks`, non-`Real` arrays are returned unchanged. A `PermutedDimsArray` gives one
with the same permutation.
"""
mask_invalid(A) = eltype(A) <: Real ? mask_invalid(A, ValidityChecks(A)) : A
mask_invalid(A, c::ValidityChecks, dims = nothing) = mask_invalid!(_similar(A, _float(eltype(A))), A, c, dims)

# Same memory order as `A`: a copy in another order is a transpose, far slower than the masking.
_similar(A::PermutedDimsArray{<:Any, N, perm}, ::Type{F}) where {N, perm, F} = PermutedDimsArray(similar(parent(A), F), perm)
_similar(A, ::Type{F}) where {F} = similar(A, F)

"""
    mask_invalid!(B, A, checks = ValidityChecks(A), dims = nothing)

[`mask_invalid`](@ref) written into `B`, which may be `A`.
"""
function mask_invalid!(B::AbstractArray, A::AbstractArray, c::ValidityChecks = ValidityChecks(A), dims = nothing)
    size(B) == size(A) || throw(DimensionMismatch("source and destination sizes differ"))
    _mask_invalid!(_storage(B), _storage(A), c, _component_dims(A, _ncomponents(c), dims))
    return B
end

# A variable's Cartesian indexing would make the kernels' `reshape` a slow `ReshapedArray`.
_storage(A::AbstractDataVariable) = _storage(parent(A))
_storage(A) = A

# Like xarray's CF decoding: Float16 overflows sums past 65504.
_float(::Type{<:Union{Int8, UInt8, Int16, UInt16, Float16}}) = Float32
_float(::Type{T}) where {T} = float(T)

_vec(::Type{C}, ::Nothing, default) where {C} = C[default]
_vec(::Type{C}, v::AbstractVector, _) where {C} = C[C(x) for x in v]
_vec(::Type{C}, x, _) where {C} = C[C(x)]

_component_dims(A, n, d::Integer) = d:d
_component_dims(A, n, d::AbstractUnitRange) = d
# No CDAWeb master bounds a whole multidimensional record.
function _component_dims(A, n, ::Nothing)
    n == 1 && return 1:1
    d = depend_1_dimnum(A)
    !isnothing(d) && size(A, d) == n && return d:d
    throw(DimensionMismatch("$n components do not match `depend_1` of an array of size $(size(A))"))
end

# Masks the parents, in memory order. Components spanning several dimensions are flattened in `A`'s order,
# which the permutation would change: those take the generic kernels, behind a barrier so they compile only when used.
function _mask_invalid!(B::PermutedDimsArray{<:Any, N, perm}, A::PermutedDimsArray{<:Any, N, perm}, c, dims::AbstractUnitRange) where {N, perm}
    length(dims) == 1 || _ncomponents(c) == 1 || (_mask_reshaped!(B, Base.inferencebarrier(A), c, dims); return B)
    d = perm[first(dims)]
    _mask_reshaped!(parent(B), parent(A), c, d:d)
    return B
end
_mask_invalid!(B, A, c, dims::AbstractUnitRange) = _mask_reshaped!(B, A, c, dims)

# Reshaped so the kernels compile once whatever `ndims(A)`: (before, components, after), or a vector for tiling.
function _mask_reshaped!(B, A, c, dims::AbstractUnitRange)
    # On storage, where `dataids` see the memory and `copy` keeps the type.
    B !== A && Base.mightalias(B, A) && return _mask_reshaped!(B, copy(A), c, dims)
    n = _ncomponents(c)
    sz(r) = (p = 1; for i in r; p *= size(A, i); end; p)
    shape = n == 1 ? (length(A), 1, 1) : (sz(1:(first(dims) - 1)), sz(dims), sz((last(dims) + 1):ndims(A)))
    n in (1, shape[2]) || throw(DimensionMismatch("$n components along dimensions $dims of an array of size $(size(A))"))
    f, lo, hi = _fill(c), c.validmin, c.validmax
    if shape[1] == 1 && n > 1
        _mask_tiled!(vec(B), vec(A), n, f, lo, hi)
    else
        _mask_kernel!(reshape(B, shape), reshape(A, shape), f, lo, hi)
    end
    return B
end

# `ivdep` in both kernels: `B` is `A` or does not overlap it, and each iteration reads and writes one index.
# NaN data failing every comparison stays NaN anyway.
@inline function _masked(::Type{F}, ::Type{C}, x, f, l, h) where {F, C}
    y = C(x)
    return ifelse(_isfill(y, f) | (y < l) | (y > h), F(NaN), F(x))
end

_isfill(y, f) = y == f
_isfill(y, ::Nothing) = false

# A fill outside `[l, h]`, as most CDAWeb fills are, fails the range check anyway: the kernels get `nothing`
# and skip its comparison. Compiled loop variants, as a runtime flag in the loop breaks vectorization.
# Not in `_mask_reshaped!`, which is inferred per array type.
_fill(c::ValidityChecks) = any(((f, l, h) -> l <= f <= h).(_fields(c)...)) ? c.fillval : nothing

_component(v, c) = length(v) == 1 ? v[1] : v[c]
_component(::Nothing, c) = nothing

function _mask_kernel!(B::AbstractArray{F, 3}, A::AbstractArray{<:Any, 3}, fill, lo::Vector{C}, hi::Vector{C}) where {F, C}
    @inbounds for k in axes(A, 3), c in axes(A, 2)
        f, l, h = map(v -> _component(v, c), (fill, lo, hi))
        @simd ivdep for i in axes(A, 1)
            B[i, c, k] = _masked(F, C, A[i, c, k], f, l, h)
        end
    end
    return B
end

_tile(v, L) = repeat(v, L ÷ length(v))
_tile(::Nothing, L) = nothing

# Components along the first dimension (ISTP layout) would make the kernel's inner loop one element
# long, too short to vectorize; checks repeated over tiles of whole records keep it contiguous.
function _mask_tiled!(B::AbstractArray{F}, A, n, fill, lo::Vector{C}, hi::Vector{C}) where {F, C}
    L = n * cld(64, n)
    f, l, h = map(v -> _tile(v, L), (fill, lo, hi))
    N = length(A)
    @inbounds for s in 0:L:(N - 1)
        @simd ivdep for j in 1:min(L, N - s)
            B[s + j] = _masked(F, C, A[s + j], isnothing(f) ? f : f[j], l[j], h[j])
        end
    end
    return B
end
