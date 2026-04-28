abstract type AbstractTimeRanges end

# https://docs.sunpy.org/en/stable/generated/api/sunpy.time.TimeRange.html#sunpy.time.TimeRange.window
"""
    TimeRanges(t0, t1, cadence=t1-t0, window=cadence)

Iterator of `(t_start, t_stop)` windows of length `window`, stepping by `cadence` from `t0` to `t1`.
"""
struct TimeRanges{T, P1, P2} <: AbstractTimeRanges
    start::T
    stop::T
    cadence::P1
    window::P2
end

TimeRanges(t0, t1, cadence = t1 - t0) = TimeRanges(t0, t1, cadence, cadence)

Base.length(iter::TimeRanges) = cld(iter.stop - iter.start, iter.cadence)
Base.eltype(::Type{<:TimeRanges{T}}) where {T} = NTuple{2, T}

function Base.iterate(iter::TimeRanges, current = iter.start)
    current > iter.stop && return nothing
    tstop = current + iter.window
    next_start = current + iter.cadence
    return (current, tstop), next_start
end

Base.@propagate_inbounds function Base.getindex(iter::TimeRanges, i::Int)
    @boundscheck 1 <= i <= length(iter) || throw(BoundsError(iter, i))
    t_start = iter.start + (i - 1) * iter.cadence
    return t_start, t_start + iter.window
end

"""
    ContinuousTimeRanges(times, max_dt)

Iterator of `(t_start, t_stop)` spans over `times`, splitting wherever consecutive values differ by more than `max_dt`.
"""
struct ContinuousTimeRanges{T, P} <: AbstractTimeRanges
    times::T
    max_dt::P
end

Base.IteratorSize(::Type{<:ContinuousTimeRanges}) = Base.SizeUnknown()
Base.eltype(::Type{<:ContinuousTimeRanges{T}}) where {T} = NTuple{2, eltype(T)}

function Base.iterate(iter::ContinuousTimeRanges, start_idx = 1)
    times = iter.times
    start_idx > length(times) && return nothing

    range_start = times[start_idx]
    prev_time = range_start

    for i in (start_idx + 1):length(times)
        current_time = times[i]
        if current_time - prev_time > iter.max_dt
            return (range_start, prev_time), i
        end
        prev_time = current_time
    end
    return (range_start, last(times)), length(times) + 1
end

# Window spec yielding `(coords[i] - before, coords[i] + after)` for each index `i`.
struct PointWindows{C, B, A}
    coords::C
    before::B
    after::A
end

Base.length(pw::PointWindows) = length(pw.coords)
Base.eltype(::Type{PointWindows{C, B, A}}) where {C, B, A} = NTuple{2, eltype(C)}

Base.@propagate_inbounds function Base.getindex(pw::PointWindows, i::Int)
    t = pw.coords[i]
    return t - pw.before, t + pw.after
end

"""
    WindowedView(data, coords, windows; dim=1)
    WindowedView(data, coords, before, after; dim=1)

`AbstractVector` of views into `data`, one per time window. `wv[i]` returns the slice of `data` along dimension `dim` whose `coords` fall within the i-th window.

`windows` is any indexable source of `(t_start, t_stop)` pairs (e.g. `TimeRanges`). The `before`/`after` form builds a symmetric window around each point in `coords`. Requires `coords` to be sorted.
"""
struct WindowedView{dim, T, D, C, W} <: AbstractVector{T}
    data::D
    coords::C
    windows::W
end

@inline _dim_view(data, ::Val{dim}, i) where {dim} =
    view(data, ntuple(k -> k == dim ? i : Colon(), Val(ndims(data)))...)

function WindowedView(data::D, coords::C, windows::W; dim = ndims(data)) where {D, C, W}
    T = Core.Compiler.return_type(_dim_view, Tuple{D, Val{dim}, UnitRange{Int}})
    return WindowedView{dim, T, D, C, W}(data, coords, windows)
end

WindowedView(data, coords, before, after; kw...) =
    WindowedView(data, coords, PointWindows(coords, before, after); kw...)

Base.size(wv::WindowedView) = (length(wv.windows),)

Base.@propagate_inbounds function Base.getindex(wv::WindowedView{dim}, i::Int) where {dim}
    t_start, t_stop = wv.windows[i]
    lo = searchsortedfirst(wv.coords, t_start)
    hi = searchsortedlast(wv.coords, t_stop)
    return _dim_view(wv.data, Val(dim), lo:hi)
end
