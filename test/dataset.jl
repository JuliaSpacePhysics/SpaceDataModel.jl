@testitem "DataSet" begin
    var1 = [1, 2, 3]
    var2 = (4, 5, 6)
    dataset = DataSet("Dataset Name", [var1, var2])
    @test size(dataset) == (2,)
    @test length(dataset) == size(dataset, 1) == 2
    @test dataset[1] === var1
    @test dataset[2] === var2
    @test dataset[1:2] == [var1, var2]

    dataset2 = DataSet("Dataset Name", Dict("key1" => var1, "key2" => var2))
    @test length(dataset2) == 2
    @test dataset2["key1"] === var1
    @test dataset2["key2"] === var2
    @test dataset2[2] ∈ (var1, var2)
    @test_throws BoundsError dataset2[3]
end

@testitem "Loading dataset from LDataSet" begin
    using SpaceDataModel: LDataSet, DataSet
    data = Dict("numberdensity" => "mms{probe}_{data_type}_numberdensity_{data_rate}")
    format = "MMS{probe}_FPI_{data_rate}_L2_{data_type}-MOMS"
    metadata = Dict("data_rates" => ["fast", "brst"])
    ld = @test_nowarn LDataSet(; name = "Test", data, format, metadata)
    ds = @test_nowarn DataSet(ld; probe = 1, data_rate = "fast", data_type = "des")
    @test ds.name == "MMS1_FPI_FAST_L2_DES-MOMS"
    @test ds.data["numberdensity"] == "mms1_des_numberdensity_fast"
end
