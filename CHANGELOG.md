## 0.13.1

- Introduces `parseMultiGameLazy` and `PgnLazyGame` for lazy parsing of PGN
  files. These APIs allow you to iterate through games in a PGN file without
  parsing the moves (only the headers).

## 0.13.0

**Breaking changes:**

- Remove `fast_immutable_collections` dependency. Public APIs that previously returned `IMap` or `IList` now return standard Dart collections:
  - `Position.legalMoves` returns `Map<Square, SquareSet>` (was `IMap<Square, SquareSet>`)
  - `Board.materialCount` returns `ByRole<int>` / `Map<Role, int>` (was `IMap<Role, int>`)
  - `Castles.rooksPositions` returns `BySide<ByCastlingSide<Square?>>` / `Map` (was `IMap`-backed)
  - `Castles.paths` returns `BySide<ByCastlingSide<SquareSet>>` / `Map` (was `IMap`-backed)
  - `PgnComment.shapes` returns `List<PgnCommentShape>` (was `IList<PgnCommentShape>`)
  - `makeLegalMoves()` returns `Map<Square, Set<Square>>` (was `IMap<Square, ISet<Square>>`)
  - The `BySide<T>`, `ByRole<T>`, and `ByCastlingSide<T>` typedefs are now aliases for standard `Map` types.
- `Pockets.value` is removed; use `Pockets.of(side, role)`, `Pockets.count(role)`, `Pockets.size`, `Pockets.hasQuality(side)`, and `Pockets.hasPawn(side)` instead.

The `Position` class remains completely immutable. Only the return types of some
methods have changed to use standard Dart collections instead of immutable
collections.

## 0.12.3

- Fix `Crazyhouse.isGameOver` and `Crazyhouse.isCheckmate` in positions where all legal moves are drop moves.

## 0.12.2

- Add `SquareSet explosionSquares(Move move)` method to Atomic class.

## 0.12.1

- Fix a bug in `Horde.hasInsufficientMaterial` that would cause a stack overflow if only one pawn was left.
- Fix insufficient material detection when the Horde has a lone Queen.
- Horde positions where the king is white instead of black are now correctly considered invalid.

## 0.12.0

- Fix an en passant bug in crazyhouse and atomicchess variants. Now the perft tests
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
