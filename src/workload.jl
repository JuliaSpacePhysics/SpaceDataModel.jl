function workload()
    io = IOContext(IOBuffer(), :color => true)
    pattern = FilePattern("https://example.com/{probe|U}/{probe}_{level}_{t:yyyymmdd}_v{version}.cdf")
    pattern(DateTime(2020, 1, 1); probe="a", level="l1", version="01")

    ds = Dataset("demo_{level}", Archive(pattern); selectors=(; probe=("a", "b"), level=("l1", "l2")))
    reg = Registry("reg", [ds]; defaults=(; probe="a"))
    show(io, MIME"text/plain"(), ds)
    show(io, MIME"text/plain"(), reg)
    show(io, MIME"text/plain"(), ds["var1"])
    reg[probe="b", level="l2"]
    foreach(_mask_workload, (Float32, Float64, Int8, Int16, Int32, UInt8, UInt16, UInt32))
    return
end

function _mask_workload(::Type{T}) where {T}
    mask_invalid(T[1 2; 3 4], ValidityChecks(T, T(1), [T(0), T(0)], T(3)))
    return mask_invalid(T[1, 2])
end

ccall(:jl_generating_output, Cint, ()) == 1 && workload()
