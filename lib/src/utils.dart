import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'models.dart';
import 'position.dart';

/// Returns all the legal moves of the [Position] in a convenient format.
///
/// Includes both possible representations of castling moves (unless `chess960` is true).
IMap<Square, ISet<Square>> makeLegalMoves(
  Position pos, {
  bool isChess960 = false,
  CastlingMethod castlingMethod = CastlingMethod.both,
}) {
  final Map<Square, ISet<Square>> result = {};
  final Map<Square, Square> castlingSquares = {
    Square.a1: Square.c1,
    Square.a8: Square.c8,
    Square.h1: Square.g1,
    Square.h8: Square.g8
  };

  for (final entry in pos.legalMoves.entries) {
    final dests = entry.value.squares;
    if (dests.isNotEmpty) {
      final from = entry.key;
      final destSet = dests.toSet();
      if (!isChess960 &&
          from == pos.board.kingOf(pos.turn) &&
          entry.key.file == 4) {
        switch (castlingMethod) {
          case CastlingMethod.kingOverRook:
            break;
          case CastlingMethod.both:
            castlingSquares.forEach((k, v) {
              if (dests.contains(k)) {
                destSet.add(v);
              }
            });
          case CastlingMethod.kingTwoSquares:
            castlingSquares.forEach((k, v) {
              if (dests.contains(k)) {
                destSet.add(v);
                destSet.remove(k);
              }
            });
        }
      }
      result[from] = ISet(destSet);
    }
  }
  return IMap(result);
}

enum CastlingMethod { kingOverRook, kingTwoSquares, both }
