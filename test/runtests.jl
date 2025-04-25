using TestItems, TestItemRunner
using Test

@run_package_tests

@testset "SpaceDataModel.jl" begin
    # Write your tests here.
end

@testitem "Aqua" begin
    using Aqua
    Aqua.test_all(SpaceDataModel)
end

@testitem "Project" begin
    project = Project(name="Project Name")
    instrument = Instrument(name="Instrument Name")
    dataset = DataSet(name="Dataset Name")
    push!(project, instrument, dataset)
    push!(instrument, dataset)
    @test length(project.instruments) == 1
    @test length(project.datasets) == 1
    @test length(instrument.datasets) == 1
end

@testitem "DataSet" begin
    var1 = [1, 2, 3]
    var2 = (4, 5, 6)
    dataset = DataSet("Dataset Name", [var1, var2])
    @test length(dataset) == 2
    @test dataset[1] === var1
    @test dataset[2] === var2
    @test dataset[1:2] == [var1, var2]

    dataset2 = DataSet("Dataset Name", Dict("key1" => var1, "key2" => var2))
    @test length(dataset2) == 2
    @test dataset2["key1"] === var1
    @test dataset2["key2"] === var2
    @test dataset2[2] ∈ (var1, var2)
end

@testitem "tryparse_datetime" begin
    using SpaceDataModel: tryparse_datetime
    using SpaceDataModel.Dates: DateTime
    @test tryparse_datetime("2001-01-01") == DateTime(2001, 1, 1)
    @test tryparse_datetime("2001-01-01T05:00:00Z") == DateTime(2001, 1, 1, 5, 0, 0, 0)
    @test tryparse_datetime("1999-01Z") == DateTime(1999, 1, 1)
    @test tryparse_datetime("1999-032T02:03:05Z") == DateTime(1999, 2, 1, 2, 3, 5, 0)
    @test tryparse_datetime("1999-032T02:04") == DateTime(1999, 2, 1, 2, 4, 0, 0)

    dts = [
        "1989Z", "1989-01Z", "1989-001Z",
        "1989-01-01Z", "1989-001T00Z",
        "1989-01-01T00Z", "1989-001T00:00Z",
        "1989-01-01T00:00Z", "1989-001T00:00:00.Z",
        "1989-01-01T00:00:00.Z", "1989-01-01T00:00:00.0Z",
        "1989-001T00:00:00.0Z", "1989-01-01T00:00:00.00Z",
        "1989-001T00:00:00.00Z", "1989-01-01T00:00:00.000Z",
        "1989-001T00:00:00.000Z", "1989-01-01T00:00:00.0000Z",
        "1989-001T00:00:00.0000Z", "1989-01-01T00:00:00.00000Z",
        "1989-001T00:00:00.00000Z", "1989-01-01T00:00:00.000000Z",
        "1989-001T00:00:00.000000Z"
    ]

    expected = DateTime(1989, 1, 1)

    for dt in dts
        @test tryparse_datetime(dt) == expected
    end
end