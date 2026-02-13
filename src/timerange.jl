abstract type AbstractTimeRanges end

# https://docs.sunpy.org/en/stable/generated/api/sunpy.time.TimeRange.html#sunpy.time.TimeRange.window
"""An iterator over a series of time ranges that are window long, with a cadence of cadence."""
struct TimeRanges{T, P1, P2} <: AbstractTimeRanges
    start::T
    stop::T
    cadence::P1
    window::P2
end

TimeRanges(t0, t1, cadence = t1 - t0) = TimeRanges(t0, t1, cadence, cadence)

Base.length(iter::TimeRanges) = cld(iter.stop - iter.start, iter.cadence)

function Base.iterate(iter::TimeRanges, current=iter.start)
    current > iter.stop && return nothing
    tstop = current + iter.window
    next_start = current + iter.cadence
    return (current, tstop), next_start
end
