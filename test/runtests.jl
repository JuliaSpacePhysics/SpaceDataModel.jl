using TestItems, TestItemRunner
using Test

@run_package_tests

@testitem "SpaceDataModel.jl" begin
    @test_nowarn SpaceDataModel.workload()
end

@testitem "General Checks" begin
    using Aqua
    using CheckConcreteStructs
    Aqua.test_all(SpaceDataModel)
    @test all_concrete(SpaceDataModel)
end

@testitem "Project" begin
    using SpaceDataModel: meta, name
    project = Project(name = "Project Name", abbreviation = "Proj", links = "links")
    instrument = Instrument(name = "Instrument Name")
    dataset = DataSet(name = "Dataset Name")
    push!(project, instrument, dataset)
    push!(instrument, dataset)
    @test name(project) == "Project Name"
    @test length(project.instruments) == 1
    @test length(project.datasets) == 1
    @test length(instrument.datasets) == 1
end

@testitem "parse_datetime" begin
    using SpaceDataModel: parse_datetime
    using SpaceDataModel.Dates: DateTime
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

    @static if VERSION < v"1.12.0-beta1"
        @test_throws ArgumentError DateTime("1999")
    else
        @test DateTime("1999") == DateTime(1999)
    end
end


@testitem "JET - Workload" begin
    using JET
    println(@report_opt ignored_modules = (Base,) SpaceDataModel.workload())
    println(@report_call ignored_modules = (Base,) SpaceDataModel.workload())
end
