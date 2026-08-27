function workload()
    io = IOContext(IOBuffer(), :color => true)
    pattern = FilePattern("https://example.com/{probe|U}/{probe}_l1_{t:yyyymmdd}_v{version}.cdf")
    ds = Dataset("demo", Archive(pattern); selectors = (; probe = ("a", "b")))
    reg = Registry("reg", [ds]; defaults = (; probe = "a"))
    show(io, MIME"text/plain"(), ds)
    show(io, MIME"text/plain"(), reg)
    show(io, MIME"text/plain"(), ds["var1"])
    reg[probe = "b"]
    return
end
