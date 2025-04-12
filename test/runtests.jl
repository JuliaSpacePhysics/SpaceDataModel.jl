using TestItems, TestItemRunner
using Test

@testset "SpaceDataModel.jl" begin
    # Write your tests here.
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
