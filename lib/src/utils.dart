import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'models.dart';
import 'position.dart';

/// Returns all the legal moves of the [Position] in a convenient format.
///
/// Includes both possible representations of castling moves (unless `chess960` is true).
IMap<Square, ISet<Square>> makeLegalMoves(
  Position pos, {
  bool isChess960 = false,
}) {
  final Map<Square, ISet<Square>> result = {};
  for (final entry in pos.legalMoves.entries) {
    final dests = entry.value.squares;
    if (dests.isNotEmpty) {
      final from = entry.key;
      final destSet = dests.toSet();
      if (!isChess960 &&
          from == pos.board.kingOf(pos.turn) &&
          entry.key.file == 4) {
        if (dests.contains(Square.a1)) {
          destSet.add(Square.c1);
        } else if (dests.contains(Square.a8)) {
          destSet.add(Square.c8);
        }
        if (dests.contains(Square.h1)) {
          destSet.add(Square.g1);
        } else if (dests.contains(Square.h8)) {
          destSet.add(Square.g8);
        }
      }
      result[from] = ISet(destSet);
    }
  }
  return IMap(result);
}
