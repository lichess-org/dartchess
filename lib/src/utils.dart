import './square_set.dart';

int squareRank(int square) => square >> 3;
int squareFile(int square) => square & 0x7;

/// Takes a string like:
/// . 1 1 1 . . . .
/// . 1 . 1 . . . .
/// . 1 . . 1 . . .
/// . 1 . . . 1 . .
/// . 1 1 1 1 . . .
/// . 1 . . . 1 . .
/// . 1 . . . 1 . .
/// . 1 . . 1 . . .
///
/// and returns a SquareSet. Useful for debugging/testing purposes.
SquareSet makeSquareSet(String rep) {
  SquareSet ret = SquareSet.empty;
  final table = rep
      .split('\n')
      .where((l) => l.isNotEmpty)
      .map((r) => r.split(' '))
      .toList()
      .reversed
      .toList();
  for (int y = 7; y >= 0; y--) {
    for (int x = 0; x < 8; x++) {
      final repSq = table[y][x];
      if (repSq == '1') {
        ret = ret.withSquare(x + y * 8);
      }
    }
  }
  return ret;
}

/// Returns the square set as a human readable string format
String printSquareSet(SquareSet sq) {
  final r = [];
  for (int y = 7; y >= 0; y--) {
    for (int x = 0; x < 8; x++) {
      final square = x + y * 8;
      r.add(sq.has(square) ? '1' : '.');
      r.add(x < 7 ? ' ' : '\n');
    }
  }
  return r.join('');
}
