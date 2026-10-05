"""
    ISTPSchema <: MetadataSchema

Schema for ISTP-compliant metadata.

# References
- [ISTP Global Attributes](https://spdf.gsfc.nasa.gov/istp_guide/gattributes.html)
- [ISTP Variables](https://spdf.gsfc.nasa.gov/istp_guide/variables.html)
"""
struct ISTPSchema <: MetadataSchema end

# DEPEND_1 is the first non-time dimension, wherever time is stored; `nothing` for a vector.
depend_1_dimnum(x) = ndims(x) < 2 ? nothing : tdimnum(x) == 1 ? 2 : 1
function depend_1(x)
    d = depend_1_dimnum(x)
    return isnothing(d) ? nothing : dims(x, d)
end

const _ISTP_SCHEMA = (
    desc = "CATDESC",
    name = "LABLAXIS" => SpaceDataModel.name,
    long_name = "FIELDNAM",
    unit = "UNITS",
    scale = "SCALETYP",
    labels = "LABL_PTR_1",
    display_type = "DISPLAY_TYPE",
    depend_1_name = Via(depend_1, ("LABLAXIS", "FIELDNAM")),
    depend_1_unit = Via(depend_1, "UNITS"),
    depend_1_scale = Via(depend_1, "SCALETYP"),
)

rules(::ISTPSchema) = _ISTP_SCHEMA
