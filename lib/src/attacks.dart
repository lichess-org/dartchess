import './square_set.dart';
import './utils.dart';

/// Gets squares attacked or defended by a king on `square`.
SquareSet kingAttacks(int square) {
  assert(square >= 0 && square < 64);
  return _kingAttacks[square];
}

/// Gets squares attacked or defended by a knight on `square`.
SquareSet knightAttacks(int square) {
  assert(square >= 0 && square < 64);
  return _knightAttacks[square];
}

/// Gets squares attacked or defended by a pawn of the given `color`
/// on `square`.
SquareSet pawnAttacks(String color, int square) {
  assert(square >= 0 && square < 64);
  assert(color == 'white' || color == 'black');
  return _pawnAttacks[color]![square];
}

// --

SquareSet _computeRange(int square, List<int> deltas) {
  SquareSet range = SquareSet.empty;
  for (final delta in deltas) {
    final sq = square + delta;
    if (0 <= sq &&
        sq < 64 &&
        (squareFile(square) - squareFile(sq)).abs() <= 2) {
      range = range.withSquare(sq);
    }
  }
  return range;
}

List<T> _tabulate<T>(T Function(int square) f) {
  final List<T> table = [];
  for (int square = 0; square < 64; square++) {
    table.insert(square, f(square));
  }
  return table;
}

final _kingAttacks =
    _tabulate((sq) => _computeRange(sq, [-9, -8, -7, -1, 1, 7, 8, 9]));
final _knightAttacks =
    _tabulate((sq) => _computeRange(sq, [-17, -15, -10, -6, 6, 10, 15, 17]));
final _pawnAttacks = {
  'white': _tabulate((sq) => _computeRange(sq, [7, 9])),
  'black': _tabulate((sq) => _computeRange(sq, [-7, -9])),
};
