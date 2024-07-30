import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import './models.dart';
import './position.dart';

/// Parses a string like 'a1', 'a2', etc. and returns a [Square] or `null` if the square
/// doesn't exist.
Square? parseSquare(String str) {
  if (str.length != 2) return null;
  final file = str.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = str.codeUnitAt(1) - '1'.codeUnitAt(0);
  if (file < 0 || file >= 8 || rank < 0 || rank >= 8) return null;
  return Square(file + 8 * rank);
}

/// Gets all the legal moves of this position as a map from the origin square to the set of destination squares.
///
/// Includes both possible representations of castling moves (unless `chess960` is true).
IMap<Square, ISet<Square>> legalMovesOf(Position pos,
    {bool isChess960 = false}) {
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

/// Utility for nullable fields in copyWith methods
class Box<T> {
  const Box(this.value);
  final T value;
}
