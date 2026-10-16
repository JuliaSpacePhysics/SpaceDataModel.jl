"""
    ISTPSchema <: MetadataSchema

Schema for ISTP-compliant metadata.

# References
- [ISTP Global Attributes](https://spdf.gsfc.nasa.gov/istp_guide/gattributes.html)
- [ISTP Variables](https://spdf.gsfc.nasa.gov/istp_guide/variables.html)
"""
struct ISTPSchema <: MetadataSchema end

# A name points to the coordinate holding the labels, which follows slicing.
function labl_ptr_1(x)
    l = resolve(x, "LABL_PTR_1")
    l isa AbstractString && x isa AbstractArray || return nothing
    d = depend_1_dimnum(x)
    return isnothing(d) ? nothing : _coord_named(x, l, d)
end

# Labels in the attribute itself outlive slicing (`v[2, :]` keeps all of them, `v[[3, 2, 1], :]` keeps their
# order), so they come after labels that follow slicing and count only when they fit.
function labl_ptr_1_values(x)
    l = resolve(x, "LABL_PTR_1")
    l isa AbstractVector || return nothing
    x isa AbstractArray || return l
    d = depend_1_dimnum(x)
    return !isnothing(d) && length(l) == size(x, d) ? l : nothing
end

# Coordinate named `n` along dimension `d` alone.
function _coord_named(x, n, d)
    c = dims(x, d)
    name(c) == n && return c
    for (axs, l) in coords(x)
        axs == (d,) && name(l) == n && return l
    end
    return nothing
end

const _ISTP_SCHEMA = (
    desc = "CATDESC",
    name = "LABLAXIS" => SpaceDataModel.name,
    long_name = "FIELDNAM",
    unit = "UNITS",
    scale = "SCALETYP",
    labels = (labl_ptr_1, dimlabels, labl_ptr_1_values),
    display_type = "DISPLAY_TYPE",
    fillval = "FILLVAL",
    validmin = "VALIDMIN",
    validmax = "VALIDMAX",
    depend_1_name = Via(depend_1, ("LABLAXIS", "FIELDNAM")),
    depend_1_unit = Via(depend_1, "UNITS"),
    depend_1_scale = Via(depend_1, "SCALETYP"),
)

rules(::ISTPSchema) = _ISTP_SCHEMA
