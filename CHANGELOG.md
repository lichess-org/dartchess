## 0.5.1

- Fix parsing PGN from smartchess

## 0.5.0

- Add new `ply` getter to `Position`
- `PgnNodeData` is no longer specified as immutable
- Make `PgnComment` really immutable

## 0.4.0

- Add `PgnNodeData` as a bound to `PgnNode` generic type parameter

## 0.3.0

- rename `Headers` to `PgnHeaders` for consistency
- `PgnGame` isn't a const constructor anymore
- tweak `parseMultiGamePgn` signature for consistency

## 0.2.0

- add `makeSan` and `makeSanUnchecked` methods to the `Position` class.
- `toSan` and `playToSan` are now deprecated.

## 0.1.0

- Initial version.
