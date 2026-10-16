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

    metadata = Dict(
        "CATDESC" => "Velocity Data",
        "LABLAXIS" => "V",
        :units => "km/s"
    )
    data = MockData([1.0, 2.0, 3.0], metadata)

    @test get_schema(data) isa ISTPSchema
    @test get_schema(() -> data) isa ISTPSchema

    attrs = schema(data)
    @test attrs[:desc] == schema(data, :desc) == "Velocity Data"
    @test attrs[:name] == "V"
    @test attrs[:units] == "km/s"
    @test haskey(attrs, :desc) && !haskey(attrs, :validmin)
end


@testitem "Empty Metadata Handling" setup = [MetadataTest] begin
    schema = ISTPSchema()
    metadata = Dict{String, Any}()
    data = MockData([1.0, 2.0], metadata)
    sl = schema(data)
    @test isnothing(sl[:title])
    @test get(sl, :title, "default") == "default"
end

@testitem "labels follow the DEPEND_1 axis" begin
    using SpaceDataModel: DataVariable, ISTPSchema, get_schema
    using Dates
    ts = DateTime(2020) .+ Day.(0:1)
    meta = Dict("CATDESC" => "flux", "LABL_PTR_1" => ["lo", "mid", "hi"])
    labels(x) = ISTPSchema()(x, :labels)
    ch = 1 => DataVariable(["E1", "E2", "E3"]; name = "ch")
    v = DataVariable(rand(3, 2); time = 2 => ts, dims = (1 => [1.0, 2.0, 3.0],), coords = (ch,), metadata = Dict("CATDESC" => "flux", "LABL_PTR_1" => "ch"))
    @test labels(v[2:3, :]) == ["E2", "E3"]  # the coordinate `LABL_PTR_1` names
    @test isnothing(labels(DataVariable(rand(3, 2); time = 2 => ts, dims = (1 => [1.0, 2.0, 3.0],), coords = (ch,))))  # strings alone are not labels
    @test isnothing(labels(v[2, :]))         # the attribute lists 3 channels, not 1
    @test isnothing(labels(DataVariable(rand(2); time = ts, metadata = Dict("CATDESC" => "B", "LABL_PTR_1" => "label_b"))))
    @test isnothing(labels(Dict("CATDESC" => "B", "LABL_PTR_1" => "label_b")))
    @test labels(DataVariable(rand(3, 2); time = 2 => ts, dims = (1 => ["x", "y", "z"],), metadata = meta)[[3, 2, 1], :]) == ["z", "y", "x"]
    @test labels(DataVariable(rand(3, 2); time = 2 => ts, metadata = meta)) == ["lo", "mid", "hi"]
    # a time-varying DEPEND_1 is laid out like the variable, here time first
    @test labels(DataVariable(rand(2, 3); time = 1 => ts, dims = (2 => rand(2, 3),), coords = (2 => DataVariable(["E1", "E2", "E3"]; name = "ch"),), metadata = Dict("LABL_PTR_1" => "ch"))[:, 2:3]) == ["E2", "E3"]
    plain = DataVariable(rand(3, 2); time = 2 => ts, dims = (1 => ["E1", "E2", "E3"],))
    @test get_schema(plain)(plain[[1, 3], :], :labels) == ["E1", "E3"]  # any schema
end

@testitem "SchemaDict" begin
    using SpaceDataModel: SchemaDict, ISTPSchema, DefaultSchema, get_schema

    @testset "K, V inferred from wrapped dict" begin
        t = SchemaDict(ISTPSchema(), Dict("UNITS" => "km/s"))
        @test t isa AbstractDict{String, String}
        @test eltype(t) === Pair{String, String}
    end

    @testset "AbstractDict interface" begin
        t = SchemaDict(ISTPSchema(), "UNITS" => "km/s")
        @test haskey(t, "UNITS")
        @test get(t, "UNITS", "default") == "km/s"
        @test "UNITS" in keys(t)
        @test length(t) == 1
        # Mutability when underlying dict is mutable
        t["new"] = "value"
        @test t["new"] == "value"

        # Iteration
        pairs_collected = collect(t)
        @test length(pairs_collected) == 2
    end

    @testset "Schema dispatch (no content sniffing)" begin
        # Explicit DefaultSchema overrides content sniffing
        t_default = SchemaDict(DefaultSchema(), "CATDESC" => "would be ISTP")
        @test get_schema((; metadata = t_default)) isa DefaultSchema
    end
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
        @test resolve(metadata, :UNITS) == "km/s"  # Symbol coerces to String
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
