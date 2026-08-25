# Changelog

## [Unreleased]

## [0.3.0] - In Development

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
- The `meta` alias (use `getmeta`), `NoData` alias, metadata access via
  `var["key"]`/`get(var, key)`/`Base.get` on model types (use `getmeta`), `push!`/`insert!` on containers.

## [0.2.0] - 2025-08-14

### Added

- CHANGELOG.md tracking notable changes
- Metadata handling interface functions `getmeta`, `setmeta`, `setmeta!`

### Removed

- **Breaking**: remove function `abbr` (previously exported)


[unreleased]: https://github.com/JuliaSpacePhysics/SpaceDataModel.jl/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/JuliaSpacePhysics/SpaceDataModel.jl/releases/tag/v0.2.0