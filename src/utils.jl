# https://github.com/rafaqz/DimensionalData.jl/blob/main/src/Dimensions/show.jl#L5
function colors(i)
    colors = [209, 32, 81, 204, 249, 166, 37]
    c = rem(i - 1, length(colors)) + 1
    colors[c]
end