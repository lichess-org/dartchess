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

/// Gets squares attacked or defended by a bishop on `square`, given `occupied`
/// squares.
SquareSet bishopAttacks(int square, SquareSet occupied) {
  final bit = SquareSet.fromSquare(square);
  return _hyperbola(bit, _diagRange[square], occupied)
      .xor(_hyperbola(bit, _antiDiagRange[square], occupied));
}

/// Gets squares attacked or defended by a rook on `square`, given `occupied`
/// squares.
SquareSet rookAttacks(int square, SquareSet occupied) {
  return _fileAttacks(square, occupied).xor(_rankAttacks(square, occupied));
}

/// Gets squares attacked or defended by a queen on `square`, given `occupied`
/// squares.
SquareSet queenAttacks(int square, SquareSet occupied) =>
    bishopAttacks(square, occupied).xor(rookAttacks(square, occupied));

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

final _fileRange =
    _tabulate((sq) => SquareSet.fromFile(squareFile(sq)).withoutSquare(sq));
final _rankRange =
    _tabulate((sq) => SquareSet.fromRank(squareRank(sq)).withoutSquare(sq));
final _diagRange = _tabulate((sq) {
  final shift = 8 * (squareRank(sq) - squareFile(sq));
  return (shift >= 0
          ? SquareSet.diagonal.shl(shift)
          : SquareSet.diagonal.shr(-shift))
      .withoutSquare(sq);
});
final _antiDiagRange = _tabulate((sq) {
  final shift = 8 * (squareRank(sq) + squareFile(sq) - 7);
  return (shift >= 0
          ? SquareSet.antidiagonal.shl(shift)
          : SquareSet.antidiagonal.shr(-shift))
      .withoutSquare(sq);
});

SquareSet _hyperbola(SquareSet bit, SquareSet range, SquareSet occupied) {
  SquareSet forward = occupied.intersect(range);
  SquareSet reverse =
      forward.flipVertical(); // Assumes no more than 1 bit per rank
  forward = forward.minus(bit);
  reverse = reverse.minus(bit.flipVertical());
  return forward.xor(reverse.flipVertical()).intersect(range);
}

SquareSet _fileAttacks(int square, SquareSet occupied) =>
    _hyperbola(SquareSet.fromSquare(square), _fileRange[square], occupied);

SquareSet _rankAttacks(int square, SquareSet occupied) {
  final range = _rankRange[square];
  final bit = SquareSet.fromSquare(square);
  SquareSet forward = occupied.intersect(range);
  SquareSet reverse = forward.mirrorHorizontal();
  forward = forward.minus(bit);
  reverse = reverse.minus(bit.mirrorHorizontal());
  return forward.xor(reverse.mirrorHorizontal()).intersect(range);
}
