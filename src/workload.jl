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
    _mask_workload(Float32); _mask_workload(Float64); _mask_workload(Int8); _mask_workload(Int16); _mask_workload(Int32)
    return
end

_mask_workload(::Type{T}) where {T} = mask_invalid(T[1 2; 3 4]; fillval = T(1), validmin = [T(0), T(0)], validmax = T(3))

ccall(:jl_generating_output, Cint, ()) == 1 && workload()
