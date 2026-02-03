## 0.12.0

- Fix an en passant bug in crackyhouse and atomichess variants. Now the perft tests
  cover these variants as well.

## 0.11.1

- Add the current FEN information to `PlayException` messages.

## 0.11.0

- Rename `makeLegalMove` parameter `isChess960` to
  `includeAlternateCastlingMoves` and invert its meaning. It now defaults to
  `false`.

## 0.10.0

- Remove the type parameter from `Position` class.
- Update dependencies.

## 0.9.2

- Fixes castling rights parsing from FEN.
- The FEN parser and writer now preserve syntactically valid castling rights even if there is no matching rook or king. Rename `unmovedRooks` to `castlingRights`.

## 0.9.1

- Fixes bugs in the PGN parser.

## 0.9.0

- `PieceKind` is now an enum.

## 0.8.0

### Breaking changes:
- `Square` is now an extension type.
- Introduce `File` and `Rank` types.

### Bug fixes:
- Fix `Position.isLegal` that was generating illegal king moves.
- Fix `Position.normalizeMove` that could turn an illegal move into a legal castling move.

## 0.7.1

- Add Piece.kind, Role.letter and Role.uppercaseLetter getters.

## 0.7.0

- Migrate SquareSet to an extension type.

## 0.6.1

- Upgrade fast_immutable_collections to version 10.0.0.

## 0.6.0

- Rename Rules to Rule and add rule getter to Position

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
