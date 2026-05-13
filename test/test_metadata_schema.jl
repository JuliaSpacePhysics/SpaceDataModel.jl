# Mock data structure for testing
@testsnippet MetadataTest begin
    using SpaceDataModel: get_schema
    using SpaceDataModel: ISTPSchema

    struct MockData{T, M}
        data::T
        metadata::M
    end

    SpaceDataModel.meta(d::MockData) = d.metadata
    Base.eltype(::Type{MockData{T, M}}) where {T, M} = eltype(T)
end

@testitem "Extract Attributes" setup = [MetadataTest] begin
    schema = ISTPSchema()

    @test :desc in keys(schema)

    metadata = Dict(
        "CATDESC" => "Velocity Data",
        "LABLAXIS" => "V",
        :units => "km/s"
    )
    data = MockData([1.0, 2.0, 3.0], metadata)

    @test get_schema(data) isa ISTPSchema
    @test get_schema(() -> data) isa ISTPSchema

    attrs = schema(data)
    @test haskey(attrs, :desc)
    @test haskey(attrs, :units)
    @test attrs[:desc] == schema(data, :desc) == "Velocity Data"
    @test attrs[:name] == "V"
    @test attrs[:units] == "km/s"
end


@testitem "Empty Metadata Handling" setup = [MetadataTest] begin
    schema = ISTPSchema()
    metadata = Dict{String, Any}()
    data = MockData([1.0, 2.0], metadata)
    sl = schema(data)
    @test isnothing(sl[:title])
    @test get(sl, :title, "default") == "default"
end

@testitem "resolve Patterns" begin
    using SpaceDataModel: resolve, Via

    metadata = Dict(
        "UNITS" => "km/s",
        "units" => "m/s",
        "LABLAXIS" => "Velocity",
        "DEPEND_0" => Dict("UNITS" => "seconds")
    )

    @testset "Direct lookup" begin
        @test resolve(metadata, "UNITS") == "km/s"
        @test resolve(metadata, :UNITS) === nothing
        @test resolve(metadata, "MISSING") === nothing
        @test resolve(metadata, md -> get(md, "name", "default")) == "default"
    end

    @testset "Priority lookup" begin
        @test resolve(metadata, ("UNITS", "units")) == "km/s"
        @test resolve(metadata, ("missing", "units")) == "m/s"
        @test isnothing(resolve(metadata, ("missing1", "missing2")))
    end

    @testset "Via accessor" begin
        accessor = data -> data["DEPEND_0"]
        @test resolve(metadata, Via(accessor, "UNITS")) == "seconds"
        @test isnothing(resolve(metadata, Via(accessor, "MISSING")))
    end

    @testset "Default value" begin
        @test resolve(metadata, "UNITS" => "default") == "km/s"
        @test resolve(metadata, "MISSING" => "default") == "default"
        @test resolve(metadata, "MISSING" => "default") == "default"
        @test resolve(metadata, ("UNITS", "units") => "default") == "km/s"
    end

    @testset "Computed default" begin
        compute_default = data -> get(data, "LABLAXIS", "computed")
        @test resolve(metadata, "UNITS" => compute_default) == "km/s"
        @test resolve(metadata, "MISSING" => compute_default) == "Velocity"
    end

    @testset "Chained Via" begin
        accessor = data -> data["DEPEND_0"]
        @test resolve(metadata, Via(accessor, "UNITS" => "default")) == "seconds"
        @test resolve(metadata, Via(accessor, "MISSING" => "default")) == "default"
        @test resolve(metadata, Via(accessor, ("UNITS", "units"))) == "seconds"
    end
end
