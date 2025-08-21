function workload()
    io = IOContext(IOBuffer(), :color => true)
    var1 = [1, 2, 3]
    var2 = (4, 5, 6)
    var = DataVariable([1, 2, 3], Dict("name" => "var"))
    var2 = DataVariable([1, 2, 3], (; name = "var2"))
    dataset = DataSet("Dataset Name", [var1, var2])
    project = Project(name = "Project Name", abbreviation = "Proj", links = "links")
    instrument = Instrument(name = "Instrument Name")
    show(io, MIME"text/plain"(), var)
    show(io, MIME"text/plain"(), var2)
    show(io, MIME"text/plain"(), dataset)
    show(io, MIME"text/plain"(), project)
    push!(project, instrument, dataset)
    push!(instrument, dataset)
    push!(dataset, var)
    return
end
