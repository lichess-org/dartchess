/// A set of squares represented by a 64 bit integer mask, using little endian
/// rank-file (LERF) mapping.
/// This is how it looks like:
///
///  8 | 56 57 58 59 60 61 62 63
///  7 | 48 49 50 51 52 53 54 55
///  6 | 40 41 42 43 44 45 46 47
///  5 | 32 33 34 35 36 37 38 39
///  4 | 24 25 26 27 28 29 30 31
///  3 | 16 17 18 19 20 21 22 23
///  2 | 8  9  10 11 12 13 14 15
///  1 | 0  1  2  3  4  5  6  7
///    -------------------------
///      a  b  c  d  e  f  g  h
///
class SquareSet {
  const SquareSet(this.value);
  const SquareSet.fromSquare(int square)
      : value = 1 << square,
        assert(square >= 0 && square < 64);
  const SquareSet.fromRank(int rank)
      : value = 0xff << (8 * rank),
        assert(rank >= 0 && rank < 8);
  const SquareSet.fromFile(int file)
      : value = 0x0101010101010101 << file,
        assert(file >= 0 && file < 8);

  final int value;

  static const empty = SquareSet(0);
  static const full = SquareSet(0xffffffffffffffff);
  static const lightSquares = SquareSet(0x55AA55AA55AA55AA);
  static const darkSquares = SquareSet(0xAA55AA55AA55AA55);

  SquareSet shr(int shift) {
    if (shift >= 64) return SquareSet.empty;
    if (shift > 0) return SquareSet(value >>> shift);
    return this;
  }

  SquareSet shl(int shift) {
    if (shift >= 64) return SquareSet.empty;
    if (shift > 0) return SquareSet(value << shift);
    return this;
  }

  SquareSet complement() {
    return SquareSet(~value);
  }

  SquareSet xor(SquareSet other) {
    return SquareSet(value ^ other.value);
  }

  SquareSet union(SquareSet other) {
    return SquareSet(value | other.value);
  }

  SquareSet intersect(SquareSet other) {
    return SquareSet(value & other.value);
  }

  int size() {
    return _popcnt64(value);
  }

  bool has(int square) {
    return value & (1 << square) != 0;
  }

  SquareSet withSquare(int square) {
    return SquareSet(value | (1 << square));
  }

  String debugPrint() {
    final r = [];
    for (int y = 7; y >= 0; y--) {
      for (int x = 0; x < 8; x++) {
        final square = x + y * 8;
        r.add(has(square) ? '1' : '.');
        r.add(x < 7 ? ' ' : '\n');
      }
    }
    return r.join('');
  }

  @override
  bool operator ==(Object other) {
    return other is SquareSet &&
        other.runtimeType == runtimeType &&
        other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  toString() {
    return 'SquareSet(0x${value.toRadixString(16)})';
  }
}

int _popcnt64(n) {
  final count2 = n - ((n >>> 1) & 0x5555555555555555);
  final count4 =
      (count2 & 0x3333333333333333) + ((count2 >>> 2) & 0x3333333333333333);
  final count8 = (count4 + (count4 >>> 4)) & 0x0f0f0f0f0f0f0f0f;
  return (count8 * 0x0101010101010101) >>> 56;
}
