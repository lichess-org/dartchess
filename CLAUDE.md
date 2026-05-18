# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run all tests (exclude slow full_perft tests)
dart test -x full_perft

# Run a single test file
dart test test/position_test.dart

# Run a specific test by name
dart test --name "some test name"

# Analyze code (lint)
dart analyze

# Format code
dart format .

# Run benchmarks
dart run benchmark/dartchess_benchmark.dart

# Run perft (move generation correctness/performance test)
dart run example/perft.dart
```

## Architecture

This is a pure Dart chess rules library (`package:dartchess`) supporting standard chess and several variants. It targets native platforms only (not web).

### Core data flow

`Setup` (FEN parse) → `Position` (validated legal state) → `Move` (play/apply) → new `Position`

### Key layers

**`models.dart`** — fundamental value types: `Side`, `Role`, `Piece`, `File`, `Rank`, `Square`, `Move` (sealed: `NormalMove` / `DropMove`), `Rule` (the variant enum), `Outcome`, and exception types (`FenException`, `PositionSetupException`).

**`square_set.dart`** — `SquareSet` is a 64-bit integer bitboard (little-endian rank-file mapping). All move generation and attack computation operates on `SquareSet` values. Prefer bitwise operations over iterating squares when working in this layer.

**`attacks.dart`** — precomputed attack tables for kings and knights; bishop/rook/queen attacks via hyperbola quintessence (sliding piece attacks with `occupied` mask). Exposes `kingAttacks`, `knightAttacks`, `pawnAttacks`, `bishopAttacks`, `rookAttacks`, `queenAttacks`.

**`board.dart`** — `Board` stores piece placement as a set of overlapping `SquareSet`s (one per side, one per role). Immutable; queries like `board.bySide(side)`, `board.byRole(role)`, `board.kingOf(side)`, `board.attacksTo(square, attacker)`.

**`castles.dart`** — `Castles` tracks unmoved rooks and the path squares needed for castling legality. Supports Chess960 (king-to-rook encoding for castling moves).

**`setup.dart`** — `Setup` is a non-validated position read from FEN. Parses/emits FEN, including pocket notation for Crazyhouse and remaining checks for ThreeCheck.

**`position.dart`** — the heart of the library. `Position` is an immutable abstract base class; each variant subclasses it: `Chess`, `Antichess`, `Atomic`, `Crazyhouse`, `KingOfTheHill`, `ThreeCheck`, `RacingKings`, `Horde`. Concrete private implementations (`_Chess`, etc.) are returned by `fromSetup`. Key API:
- `Position.setupPosition(rule, setup)` — variant-aware factory
- `pos.legalMoves` — `Map<Square, SquareSet>` (king-to-rook encoding for castling)
- `pos.play(move)` / `pos.playUnchecked(move)` — returns new position
- `pos.parseSan(san)` / `pos.makeSan(move)` — SAN I/O
- `pos.isCheckmate`, `pos.isStalemate`, `pos.isGameOver`, `pos.outcome`
- Castling moves are encoded as king-to-rook; use `makeLegalMoves()` (from `utils.dart`) to also include the traditional king-to-destination squares.

**`pgn.dart`** — `PgnGame<T>` holds headers + a `PgnNode<T>` tree of moves (with variations, comments, NAGs, shapes, evaluations). `PgnGame.parsePgn` / `PgnGame.parseMultiGamePgn` for parsing; `game.makePgn()` for serialization. Use `PgnNode.transform` to walk the tree and attach computed data (e.g. FEN per node) without mutating nodes.

**`utils.dart`** — `makeLegalMoves(pos)` returns `Map<Square, Set<Square>>` adding traditional castling destinations alongside king-to-rook destinations.

**`debug.dart`** — `toSfen` helpers for printing boards in ASCII; primarily for testing and debugging.

### Immutability

All `Position`, `Board`, `Setup`, `Castles` instances are immutable (`@immutable`). Standard Dart collections are used throughout; immutability is enforced by the library's internal discipline rather than FIC types.

### Chess960

Castling is internally encoded king-to-rook throughout. `makeLegalMoves` adds the standard king-to-g/c destination for display purposes. When playing a castling move from UI, both encodings are accepted by `isLegal`.
