/// A set of squares represented by a 64 bit integer mask, using little endian
/// rank-file (LERF) mapping.
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

  int size() {
    return _popcnt64(value);
  }

  bool has(int square) {
    return value & (1 << square) != 0;
  }

  SquareSet withSquare(int square) {
    return SquareSet(value | (1 << square));
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
