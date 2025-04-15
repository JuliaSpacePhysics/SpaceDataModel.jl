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
