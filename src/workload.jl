function workload()
    io = IOContext(IOBuffer(), :color => true)
    var1 = [1, 2, 3]
    var2 = (4, 5, 6)
    dataset = DataSet("Dataset Name", (var1, var2))
    project = Project(name="Project Name", abbreviation="Proj", links="links")
    show(io, MIME"text/plain"(), dataset)
    show(io, MIME"text/plain"(), project)
end