# Changelog

## [Unreleased]

### Added

- `SpaceDataModel.DataSource`: supertype of `AbstractDataset`, `Product`, `Transformed` and `Archive`; subtypes are callable (`x(t0, t1)`).
- `SpaceDataModel.AbstractDataset`: supertype for package dataset types.
- `AbstractRegistry`: supertype for providers, keyed by id (`keys(reg)`, `reg[id]`); `Registry` subtypes it and gains `keys`, `reg[name]` and predicate `filter`. See README (Discovery).
- `SpaceDataModel.Testing.test_dataset` checks a dataset against the contract (README, Data Sources); loaded with `Test`.

### Changed

- `AbstractCatalog` is removed.
- `getdata` on a `DataSource` converts time strings and `Date`s to `DateTime` before dispatch, so methods may type `t0, t1` as `DateTime`.
- `refresh=true` re-lists each directory once per call, not once per step.

### Fixed

- `times(v)` now always derives from `dims(v, tdimnum(v))`; a `time` or `times` field is no longer read. Types storing times in such a field must return it from `dims(v, i)`, which previously fell back to `axes` and put sample indices on the time axis.

## [0.4.2] - 2026-10-07

### Added

- Time strings accept a space or `/` between date and time (`"2021-08-08 12:00"`, `"2021-08-08/12:00"`).

### Changed

- `units(v)` resolves through the metadata schema, so ISTP `UNITS` is found; the default schema's `:unit` reads `"units"`.

### Removed

- `SpaceDataModel.unit` (unexported), which threw on any multi-character unit string.

## [0.4.1] - 2026-10-05

### Added

- `mask_invalid(A; fillval, validmin, validmax, dims)` (and `mask_invalid!`): each check defaults to the schema value, so one can be overridden or disabled (`nothing`) while the others still come from metadata.

## [0.4.0] - 2026-10-05

### Added

- `SpaceDataModel.hastimedim` (unexported).
- `mask_invalid`/`mask_invalid!` with `ValidityChecks`: replace fill and out-of-range values by `NaN` (moved from CDFDatasets' `sanitize`).
- ISTP schema keys `fillval`, `validmin`, `validmax`.

### Changed

- `dim` is renamed `dims`, after Base `axes`, and gains `dims(x)`, the tuple of all dimensions. `dim` and `getdim` remain aliases.
- **Breaking**: `tdimnum(x)` returns `nothing` when `x` has no time dimension instead of warning and assuming the last one, including for a `DimArray` without a `Ti`/`:time` dimension. `timedim`/`times` throw an `ArgumentError` without a time dimension.
- **Breaking**: the `dims` field default of `dims(x, i)` (which made a `Base.ReshapedArray` return its size) and the `times`/`time` field default of `times(x)` apply only to `AbstractDataVariable` subtypes; other types get `axes(x, i)` and the time-dimension path.

### Fixed

- `depend_1` is the first non-time dimension (it returned the time dimension when time was in the middle); it returns the dimension rather than its unwrapped values, so ISTP `depend_1_*` metadata is found; it is `nothing` for a vector.

## [0.3.0] - 2026-08-27

Model-the-contract redesign. Breaking throughout.

### Added

- `Registry`: the one collection type — a relation of datasets sharing a selector
  vocabulary, with `defaults` and metadata. A mission, an instrument, or any other grouping is a `Registry`.
- `Dataset`: the one dataset type — name (may carry `{selector}` placeholders), selector domains, source, metadata.
- `Product(dataset, variable; metadata...)`: a variable of a dataset — not callable
- Sources: `Archive(pattern, reader=identity)` for URL-mirror archives.
- `getdata(x, t0, t1)`: the single I/O verb.
- `Transformed(f, source)`, spelled `f ∘ source`: a lazy derived product — `getdata`
  materializes the source and applies `f`, so transforms compose without a time range. Chains collapse onto the one source.
- `available(ds, t0, t1)`: published steps in a range.
- `FilePattern` case modifiers `{name|U}` / `{name|L}` for archives spelling one value two ways.

### Removed

- `Project` and `Instrument`: both are a `Registry` (a plain container and a selection
  policy collapsed into one relation type).
- The generic callable `Product(data, transformation)` and the abstract hierarchy
  `AbstractModel` > `AbstractProject`/`AbstractInstrument`/`AbstractProduct` >
  `AbstractDataSet`.
- `DataSet`, `LDataSet`, `format_pattern`: subsumed by `Dataset` and its source.
- The `NoData` alias, metadata access via `var["key"]`/`get(var, key)`/`Base.get` on model types (use `getmeta`).

## [0.2.0] - 2025-08-14

### Added

- CHANGELOG.md tracking notable changes
- Metadata handling interface functions `getmeta`, `setmeta`, `setmeta!`

### Removed

- **Breaking**: remove function `abbr` (previously exported)


[unreleased]: https://github.com/JuliaSpacePhysics/SpaceDataModel.jl/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/JuliaSpacePhysics/SpaceDataModel.jl/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/JuliaSpacePhysics/SpaceDataModel.jl/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/JuliaSpacePhysics/SpaceDataModel.jl/releases/tag/v0.2.0