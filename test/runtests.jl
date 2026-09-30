using Pkg
# prereleases often have no installable JET.
const RUN_JET_TESTS = isempty(VERSION.prerelease)
RUN_JET_TESTS && Pkg.add("JET")

using TestItems, TestItemRunner
using Test

@run_package_tests filter = ti -> RUN_JET_TESTS || !(:jet in ti.tags)

@testitem "SpaceDataModel.jl" begin
    SpaceDataModel.workload()
end

@testitem "General Checks" begin
    using Aqua
    using CheckConcreteStructs
    Aqua.test_all(SpaceDataModel)
    @test all_concrete(SpaceDataModel)
end

@testitem "Registry metadata" begin
    using SpaceDataModel: name, getmeta
    reg = Registry(name = "Mission Name", abbreviation = "M", links = "links")
    @test name(reg) == "Mission Name"
    @test getmeta(reg, "abbreviation") == "M"
end

@testitem "parse_datetime" begin
    using SpaceDataModel: parse_datetime
    using Dates: DateTime
    @test parse_datetime("2001-01-01") == DateTime(2001, 1, 1)
    @test parse_datetime("2001-01-01T05:00:00") == DateTime(2001, 1, 1, 5, 0, 0, 0)
    @test parse_datetime("1999-01") == DateTime(1999, 1, 1)
    @test parse_datetime("1999-002") == DateTime(1999, 1, 2)
    @test parse_datetime("1999-032T02:03:05") == DateTime(1999, 2, 1, 2, 3, 5, 0)
    @test parse_datetime("1999-032T02:04") == DateTime(1999, 2, 1, 2, 4, 0, 0)
    @test parse_datetime("1999-032T02:04:11.041") == DateTime(1999, 2, 1, 2, 4, 11, 41)

    dts = [
        "1989", "1989-01", "1989-001",
        "1989-01-01", "1989-001T00",
        "1989-01-01T00", "1989-001T00:00",
        "1989-01-01T00:00", "1989-001T00:00:00.",
        "1989-01-01T00:00:00.", "1989-01-01T00:00:00.0",
        "1989-001T00:00:00.0", "1989-01-01T00:00:00.00",
        "1989-001T00:00:00.00", "1989-01-01T00:00:00.000",
        "1989-001T00:00:00.000",
    ]

    expected = DateTime(1989, 1, 1)

    for dt in dts
        @test parse_datetime(dt) == expected
    end

    # sub-millisecond input does not fit a DateTime, in either form
    for dt in ("1989-01-01T00:00:00.0001", "1989-001T00:00:00.0001",
               "1989-001T00:00:00.000001", "1989-001T00:00:00.000000001")
        @test_throws ArgumentError parse_datetime(dt)
    end

    @static if VERSION < v"1.12.0-beta1"
        @test_throws ArgumentError DateTime("1999")
    else
        @test DateTime("1999") == DateTime(1999)
    end
end

@testitem "JET - Workload" tags = [:jet] begin
    using JET
    println(@report_opt ignored_modules = (Base,) SpaceDataModel.workload())
    @test_call SpaceDataModel.workload()
end
