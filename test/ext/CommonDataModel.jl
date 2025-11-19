@testitem "CommonDataModel Extension Tests" begin
    using CommonDataModel
    using CommonDataModel: MemoryDataset, defVar

    using SpaceDataModel: name, getmeta

    MemoryDataset(tempname(), "c") do ds
        sz = (4, 5)
        ds.dim["lon"] = sz[1]
        ds.dim["lat"] = sz[2]

        v = defVar(
            ds, "temperature", Float32, ("lon", "lat"),
            attrib = [
                "long_name" => "Temperature",
                "test_vector_attrib" => [1, 2, 3],
            ]
        )

        # write attributes
        v.attrib["units"] = "degree Celsius"
        v.attrib["comment"] = "this is a string attribute with unicode Ω ∈ ∑ ∫ f(x) dx "

        @test name(v) == "temperature"
        @test CommonDataModel.dim(v, "lon") == sz[1]
        @test getmeta(v, "units") == "degree Celsius"
        @test getmeta(v, "comment") == "this is a string attribute with unicode Ω ∈ ∑ ∫ f(x) dx "
    end
end
