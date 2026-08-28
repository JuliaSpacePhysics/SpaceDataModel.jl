@testitem "Registry selection and filterings" begin
    using SpaceDataModel: select, selectors, vocabulary, FilePattern
    using Dates
    hz = Dataset("hz_{rate}", Archive(FilePattern("{probe|U}/{probe}_{rate}_{coord}_{t:yyyymmdd}.cdf"));
        selectors=(; probe=("ts1", "ts2"), rate=("64hz", "128hz"), coord=("dsi", "gse")))
    daily = Dataset("daily", Archive(FilePattern("8sec_{t:yyyymmdd}.cdf")); selectors=(; rate="8sec"))
    open = Dataset("open", Archive(FilePattern("{rate}_{level}_{t:yyyymmdd}.cdf")); selectors=(; rate="raw", level=Any))
    reg = Registry("MGF", [hz, daily, open]; defaults=(; rate="8sec", probe="ts1", coord="dsi"))

    @test sprint(show, open.selectors) == "(rate = \"raw\", level = Any)"
    @test vocabulary(reg) == [:probe, :rate, :coord, :level]
    # A fully pinned dataset comes back as is
    @test reg[] === daily
    # A default the dataset does not carry is ignored; a supplied selector it lacks excludes it.
    ds = reg[rate="64hz"]
    @test reg[rate = "64hz"] == Dataset("hz_64hz", Archive(FilePattern("TS1/ts1_64hz_dsi_{t:yyyymmdd}.cdf")); selectors=(; probe="ts1", rate="64hz", coord="dsi"))
    @test ds.source.pattern(Date(2017, 3, 27)) == "TS1/ts1_64hz_dsi_20170327.cdf"
    @test_throws ArgumentError reg[coord="gse"]
    @test NamedTuple(reg[rate="raw", level="l2"].selectors) == (; rate="raw", level="l2")
    @test_throws ArgumentError reg[rate="raw"]
    @test_throws ArgumentError reg[rate="1hz"]
    @test NamedTuple(reg[rate="64hz", probe=:ts2].selectors).probe == "ts2"
    # A spelling outside the domain is rejected, not coerced.
    @test_throws ArgumentError reg[rate="64hz", probe="TS2"]

    # Filtering narrows and pins but never throws on an unmatched value.
    f = filter(reg; probe="ts2")
    @test [ds.name for ds in f.datasets] == ["hz_{rate}"]
    @test NamedTuple(selectors(only(f.datasets))).probe == "ts2"
    @test isempty(filter(reg; rate="1hz").datasets)
end

@testitem "getdata and variable pins" begin
    using SpaceDataModel: FilePattern, _LISTINGS
    using Dates

    src, dst = mktempdir(), mktempdir()
    names = ["f_20201001_v01.cdf", "f_20201002_v02.cdf"]
    foreach(n -> write(joinpath(src, n), "data"), names)
    dir = "file://" * src * "/"
    _LISTINGS[dir] = Threads.@spawn names
    # The reader receives the normalized range and owns the trim.
    reader(paths, t0, t1) = Dict("b" => length(paths), "trange" => (t0, t1))
    pattern = FilePattern("$(dir)f_{t:yyyymmdd}_v{version}.cdf")
    ds = Dataset("d", Archive(pattern, reader))

    expected = Dict("b" => 2, "trange" => (DateTime(2020, 10, 1), DateTime(2020, 10, 3)))
    @test getdata(ds, "2020-10-01", "2020-10-03"; dir=dst) == expected
    @test getdata(ds, ("2020-10-01", "2020-10-03"); dir=dst) == expected
    @test available(ds, "2020-10-01", "2020-10-04") == [DateTime(2020, 10, 1), DateTime(2020, 10, 2)]

    # The default reader hands back paths, and `remotefiles` on a dataset skips the cache.
    files = Dataset("f", Archive(pattern))
    @test basename.(getdata(files, "2020-10-01", "2020-10-03"; dir=dst)) == names
    @test SpaceDataModel.remotefiles(files, "2020-10-01", "2020-10-03") == dir .* names

    # A range the archive publishes nothing for throws, rather than handing the reader an
    # empty list; `available` answers the same query with an empty (typed) result.
    @test_throws ArgumentError getdata(ds, "2021-01-01", "2021-01-03"; dir=dst)
    @test available(ds, "2021-01-01", "2021-01-03") == DateTime[]

    # `ds[var]` extracts the variable out of what the reader returned.
    b = ds["b"]
    @test getdata(b, "2020-10-01", "2020-10-03"; dir=dst) == 2

    # `f ∘ product` is lazy, and re-composing fuses rather than nesting.
    t = (x -> x + 1) ∘ ((x -> x * 2) ∘ b)
    @test getdata(t, "2020-10-01", "2020-10-03"; dir=dst) == 5
    @test t.source === b
    @test available(t, "2020-10-01", "2020-10-04") == [DateTime(2020, 10, 1), DateTime(2020, 10, 2)]
    @test sprint(show, abs ∘ b) == "Transformed(abs, b)"

    # A product carries its own metadata over any getdata-able source, e.g. plot labels
    # layered on a package's source type (the Speasy/SPEDAS pattern).
    src2 = (; id="cda/X")
    SpaceDataModel.getdata(s::typeof(src2), t0, t1) = Dict("y" => (s.id, t0, t1))
    p = Product(src2, "y"; labels=["Y"], name="cda/X/y")
    @test getdata(p, 1, 2) == ("cda/X", 1, 2)
    @test SpaceDataModel.getmeta(p, :labels) == ["Y"]
    @test SpaceDataModel.name(p) == "cda/X/y"
end
