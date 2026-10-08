@testitem "Registry selection and filterings" begin
    using SpaceDataModel: select, selectors, vocabulary, FilePattern
    using Dates
    hz = Dataset("hz_{rate}", Archive(FilePattern("{probe|U}/{probe}_{rate}_{coord}_{t:yyyymmdd}.cdf"));
        selectors=(; probe=("ts1", "ts2"), rate=("64hz", "128hz"), coord=("dsi", "gse")))
    daily = Dataset("daily_{rate}", Archive(FilePattern("{rate}_{t:yyyymmdd}.cdf")); selectors=(; rate="8sec"))
    open = Dataset("open", Archive(FilePattern("{rate}_{level}_{t:yyyymmdd}.cdf")); selectors=(; rate="raw", level=Any))
    reg = Registry("MGF", [hz, daily, open]; defaults=(; rate="8sec", probe="ts1", coord="dsi"))

    @test sprint(show, open.selectors) == "(rate = \"raw\", level = Any)"
    @test vocabulary(reg) == [:probe, :rate, :coord, :level]
    @test reg[] == Dataset("daily_8sec", Archive(FilePattern("8sec_{t:yyyymmdd}.cdf")); selectors=(; rate="8sec"))
    @test reg[].source.pattern(Date(2017, 3, 27)) == "8sec_20170327.cdf"
    @test length(Set([reg[], reg[]])) == 1
    @test length(Set([Dataset("x", reg[].source; fill=NaN), Dataset("x", reg[].source; fill=NaN)])) == 1
    @test !isequal(Dataset("x", reg[].source; z=0.0), Dataset("x", reg[].source; z=-0.0))
    @test reg[] != Dataset("daily_8sec", reg[].source; selectors=(; rate="8sec"), note=1)
    # A default the dataset does not carry is ignored; a supplied selector it lacks excludes it.
    ds = reg[rate="64hz"]
    @test reg[rate = "64hz"] == Dataset("hz_64hz", Archive(FilePattern("TS1/ts1_64hz_dsi_{t:yyyymmdd}.cdf")); selectors=(; probe="ts1", rate="64hz", coord="dsi"))
    @test ds.source.pattern(Date(2017, 3, 27)) == "TS1/ts1_64hz_dsi_20170327.cdf"
    @test_throws ArgumentError reg[coord="gse"]
    @test NamedTuple(reg[rate="raw", level="l2"].selectors) == (; rate="raw", level="l2")
    @test_throws ArgumentError reg[rate="raw"]
    @test_throws ArgumentError reg[rate="1hz"]
    @test NamedTuple(reg[rate="64hz", probe=:ts2].selectors).probe == "ts2"
    @test reg[rate=SubString("64hz"), probe=[SubString("ts2")]] == reg[rate="64hz", probe="ts2"]
    # A spelling outside the domain is rejected, not coerced.
    @test_throws ArgumentError reg[rate="64hz", probe="TS2"]

    # Filtering narrows and pins but never throws on an unmatched value.
    f = filter(reg; probe="ts2")
    @test [ds.name for ds in f.datasets] == ["hz_{rate}"]
    @test NamedTuple(selectors(only(f.datasets))).probe == "ts2"
    @test isempty(filter(reg; rate="1hz").datasets)

    @test keys(reg) == ["hz_{rate}", "daily_{rate}", "open"]
    @test reg["open"] === open
    err = try reg["HZ"] catch e e end
    @test err isa ArgumentError && occursin("hz_{rate}", err.msg)
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

@testitem "test_dataset" begin
    using Test
    using Dates
    using DimensionalData: DimArray, Ti
    using SpaceDataModel: SpaceDataModel, AbstractDataset, Product, getdata
    using SpaceDataModel.Testing: test_dataset

    # Records instead of throwing, so a violating dataset can be asserted to fail.
    # test_dataset's own @testset inherits this type, hence kw..., finish and recursive fails.
    struct Recorder <: Test.AbstractTestSet
        description::String
        results::Vector{Any}
    end
    Recorder(desc; kw...) = Recorder(desc, [])
    Test.record(ts::Recorder, r) = push!(ts.results, r)
    Test.finish(ts::Recorder) = (Test.get_testset_depth() > 0 && Test.record(Test.get_testset(), ts); ts)
    fails(ts) = any(r -> r isa Recorder ? fails(r) : !(r isa Test.Pass), ts.results)
    check(ds) = fails(@testset Recorder "check" begin
        test_dataset(ds, "y", DateTime(2020, 1, 1), DateTime(2020, 1, 1, 3); empty=(DateTime(2021), DateTime(2021, 1, 2)))
    end)

    struct Toy <: AbstractDataset
        closed::Bool  # includes t1: violates the half-open contract
        direct::Int   # offset the direct path adds: violates whole[var] == ds[var]
    end
    ts = DateTime(2020, 1, 1):Hour(1):DateTime(2020, 1, 2)
    function series(ds, t0, t1, offset=0)
        sel = filter(t -> t0 <= t && (ds.closed ? t <= t1 : t < t1), ts)
        DimArray(collect(1.0:length(sel)) .+ offset, Ti(sel))
    end
    SpaceDataModel.getdata(ds::Toy, t0, t1) = Dict("y" => series(ds, t0, t1))
    SpaceDataModel.getdata(p::Product{Toy}, t0, t1) = series(parent(p), t0, t1, parent(p).direct)

    @test !check(Toy(false, 0))
    @test check(Toy(true, 0))
    @test check(Toy(false, 1))
    # A range tuple reaches the `Product{Toy}` override, not the parent's whole-dataset path.
    p = Toy(false, 1)["y"]
    @test getdata(p, (DateTime(2020, 1, 1), DateTime(2020, 1, 2))) == getdata(p, DateTime(2020, 1, 1), DateTime(2020, 1, 2))
end

@testitem "DataSource time normalization" begin
    using Dates
    using SpaceDataModel: SpaceDataModel, AbstractDataset, DataSource, Dataset, Product, getdata

    struct Typed <: AbstractDataset end
    SpaceDataModel.getdata(::Typed, t0::DateTime, t1::DateTime) = Dict("y" => (:whole, t0, t1))
    SpaceDataModel.getdata(::Product{Typed}, t0::DateTime, t1::DateTime) = (:direct, t0, t1)
    struct NoMethod <: DataSource end

    t0, t1 = DateTime(2020, 1, 1), DateTime(2020, 1, 2, 12)
    @test getdata(Typed(), "2020-01-01", "2020-01-02T12:00")["y"] == (:whole, t0, t1)
    # A string range must reach the typed `Product` override
    @test Typed()["y"]("2020-001", "2020-01-02 12:00") == (:direct, t0, t1)
    @test (last ∘ Typed()["y"])((Date(2020, 1, 1), t1)) == t1
    @test getdata(Dataset("x", (a, b) -> (a, b)), "2020-01-01", Date(2020, 1, 2)) == (t0, DateTime(2020, 1, 2))
    @test_throws ArgumentError getdata(NoMethod(), "2020-01-01", "2020-01-02")
end
