@testitem "AbstractDataVariable Broadcasting" begin
    using SpaceDataModel: AbstractDataVariable, DataVariable
    using Base.Broadcast: ArrayStyle, Broadcasted

    # Test BroadcastStyle
    var = DataVariable([1.0, 2.0, 3.0], Dict("istest" => true))
    @test Base.BroadcastStyle(typeof(var)) == ArrayStyle{AbstractDataVariable}()

    # Test broadcasting operations
    result1 = var .+ 1
    @test result1 isa DataVariable
    @test parent(result1) == [2.0, 3.0, 4.0]
end
