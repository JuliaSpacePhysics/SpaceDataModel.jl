"""
    ISTPSchema <: MetadataSchema

Schema for ISTP-compliant metadata.

# References
- [ISTP Global Attributes](https://spdf.gsfc.nasa.gov/istp_guide/gattributes.html)
- [ISTP Variables](https://spdf.gsfc.nasa.gov/istp_guide/variables.html)
"""
struct ISTPSchema <: MetadataSchema end

# Metadata outlives slicing (`v[2, :]` keeps all of `LABL_PTR_1`), so attributes count only when they fit.
# A string is the unresolved pointer, not a label.
function labl_ptr_1(x)
    l = resolve(x, "LABL_PTR_1")
    l isa AbstractVector || return nothing
    x isa AbstractArray || return l
    d = depend_1_dimnum(x)
    return !isnothing(d) && length(l) == size(x, d) ? l : nothing
end

const _ISTP_SCHEMA = (
    desc = "CATDESC",
    name = "LABLAXIS" => SpaceDataModel.name,
    long_name = "FIELDNAM",
    unit = "UNITS",
    scale = "SCALETYP",
    labels = (dimlabels, labl_ptr_1),
    display_type = "DISPLAY_TYPE",
    fillval = "FILLVAL",
    validmin = "VALIDMIN",
    validmax = "VALIDMAX",
    depend_1_name = Via(depend_1, ("LABLAXIS", "FIELDNAM")),
    depend_1_unit = Via(depend_1, "UNITS"),
    depend_1_scale = Via(depend_1, "SCALETYP"),
)

rules(::ISTPSchema) = _ISTP_SCHEMA
