@testitem "remote listing" begin
    using SpaceDataModel: _listing
    f = tempname()
    write(f, "<a href=\"x.cdf\">x</a>")
    @test _listing("file://" * f) == ["x.cdf"]
    # A directory that cannot be listed is a gap, and says why.
    @test isnothing(@test_logs (:warn, "Remote directory not listed") _listing("file://" * tempname()))
end

@testitem "index parsing" begin
    using SpaceDataModel: _index_names
    # Apache FancyIndexing (ELFIN) and HTMLTable (TRACERS)
    fancy = """<tr><td><a href="/ela/l1/state/">Parent Directory</a></td></tr>
               <tr><td><a href="?C=N;O=D">Name</a></td></tr>
               <tr><td><a href="ela_l1_state_defn_20210808_v03.cdf">x</a></td></tr>"""
    table = """<td class="indexcolname"><a href="https://tracers.physics.uiowa.edu">Home</a></td>
               <td class="indexcolname"><a href="2026/">2026</a></td>
               <td class="indexcolname"><a href="ts2_l2_ace_def_20260401_v1.1.1.cdf">y</a></td>"""
    @test _index_names(fancy) == ["ela_l1_state_defn_20210808_v03.cdf"]
    @test _index_names(table) == ["ts2_l2_ace_def_20260401_v1.1.1.cdf"]
    @test isempty(_index_names(""))
end

@testitem "version matching" begin
    using SpaceDataModel: _numkey, _name_regex
    @test _numkey("1.1.10") > _numkey("1.1.2")
    @test _numkey("01_10") > _numkey("01_02")

    re = _name_regex("ela_l1_state_defn_20210808_v*.cdf")
    @test match(re, "ela_l1_state_defn_20210808_v03.cdf").captures == ["03"]
    # One field may carry its own separators
    @test match(re, "ela_l1_state_defn_20210808_v01_10.cdf").captures == ["01_10"]
    @test isnothing(match(re, "ela_l1_state_defn_20210808_v03_beta.cdf"))
    @test isnothing(match(re, "ela_l1_state_defn_20210808_v03xcdf"))
end

@testitem "resolve_url" begin
    using SpaceDataModel: resolve_url, _LISTINGS
    dir = "file://" * mktempdir() * "/"
    seed!(names) = _LISTINGS[dir] = Threads.@spawn names

    @test resolve_url("$(dir)f_20210808_v01.cdf") == "$(dir)f_20210808_v01.cdf"

    seed!(["f_20210808_v01.cdf", "f_20210808_v1.1.10.cdf", "f_20210808_v1.1.2.cdf",
        "other_20210808_v99.cdf", "f_20210809_v99.cdf"])
    @test resolve_url("$(dir)f_20210808_v*.cdf") == "$(dir)f_20210808_v1.1.10.cdf"

    # MAVEN names a version and a revision; the revision decides only among the highest version.
    seed!(["mvn_swi_l2_coarsearc3d_20200101_v01_r09.cdf", "mvn_swi_l2_coarsearc3d_20200101_v02_r00.cdf",
        "mvn_swi_l2_coarsearc3d_20200101_v02_r01.cdf"])
    @test resolve_url("$(dir)mvn_swi_l2_coarsearc3d_20200101_v*_r*.cdf") ==
          "$(dir)mvn_swi_l2_coarsearc3d_20200101_v02_r01.cdf"

    seed!(["unrelated.cdf"])
    @test isnothing(resolve_url("$(dir)f_20210808_v*.cdf"))

    # A directory that could not be listed is a gap: nothing to resolve, but not a failure.
    seed!(nothing)
    @test isnothing(resolve_url("$(dir)f_20210808_v*.cdf"))

    # Resolution reads one listing, so the directory it lists must be named outright.
    @test_throws ArgumentError resolve_url("file:///data/*/f_20210808_v*.cdf")
end

@testitem "localize" begin
    using SpaceDataModel: localize
    using Dates
    src, dst = mktempdir(), mktempdir()
    for i in 1:3
        write(joinpath(src, "f$i.cdf"), "data$i")
    end
    urls = ["file://" * joinpath(src, "f$i.cdf") for i in 1:3]
    want = [joinpath(dst, lstrip(src, '/'), "f$i.cdf") for i in 1:3]

    @test localize(urls; dir=dst) == want
    @test read(want[1], String) == "data1"
    @test readdir(dirname(want[1])) == ["f1.cdf", "f2.cdf", "f3.cdf"]

    # Removing the source proves the second call served the cache rather than refetching.
    rm(joinpath(src, "f1.cdf"))
    @test localize(urls; dir=dst, update=Day(1)) == want
    # A file the archive claimed to have is a failure, not a gap, so it must surface...
    @test_throws Exception localize(urls[1]; dir=dst, update=true)
    # ...without stranding a partial download or destroying the copy already cached.
    @test readdir(dirname(want[1])) == ["f1.cdf", "f2.cdf", "f3.cdf"]
    @test read(want[1], String) == "data1"
end

@testitem "remotefiles" begin
    using SpaceDataModel: FilePattern, remotefiles, _LISTINGS
    using Dates

    dir = "file://" * mktempdir() * "/"
    _LISTINGS[dir] = Threads.@spawn ["f_20201001_v01.cdf", "f_20201001_v02.cdf", "f_20201003_v01.cdf"]
    p = FilePattern("$(dir)f_{t:yyyymmdd}_v{version}.cdf")

    # The 2nd is unpublished: a gap in the archive drops out rather than erroring
    @test remotefiles(p, "2020-10-01", "2020-10-04"; version="*") ==
          ["$(dir)f_20201001_v02.cdf", "$(dir)f_20201003_v01.cdf"]

    hourly = FilePattern("file:///f_{t:yyyymmddHH}.cdf"; cadence=Hour(1))
    @test length(remotefiles(hourly, Date(2020, 10, 1), Date(2020, 10, 2))) == 24
end
