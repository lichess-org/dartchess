import './models.dart';

/// A finite set of all squares on a chessboard.
///
/// All the squares are represented by a single 64-bit integer, where each bit
/// corresponds to a square, using a little-endian rank-file mapping.
/// See also [Square].
///
/// The set operations are implemented as bitwise operations on the integer.
extension type const SquareSet(int value) {
  /// Creates a [SquareSet] with a single [Square].
  const SquareSet.fromSquare(Square square) : value = 1 << square;

  /// Creates a [SquareSet] from several [Square]s.
  SquareSet.fromSquares(Iterable<Square> squares)
      : value = squares
            .map((square) => 1 << square)
            .fold(0, (left, right) => left | right);

  /// Create a [SquareSet] containing all squares of the given rank.
  const SquareSet.fromRank(Rank rank)
      : value = 0xff << (8 * rank),
        assert(rank >= 0 && rank < 8);

  /// Create a [SquareSet] containing all squares of the given file.
  const SquareSet.fromFile(File file)
      : value = 0x0101010101010101 << file,
        assert(file >= 0 && file < 8);

  /// Create a [SquareSet] containing all squares of the given backrank [Side].
  const SquareSet.backrankOf(Side side)
      : value = side == Side.white ? 0xff : 0xff00000000000000;

  static const empty = SquareSet(0);
  static const full = SquareSet(0xffffffffffffffff);
  static const lightSquares = SquareSet(0x55AA55AA55AA55AA);
  static const darkSquares = SquareSet(0xAA55AA55AA55AA55);
  static const diagonal = SquareSet(0x8040201008040201);
  static const antidiagonal = SquareSet(0x0102040810204080);
  static const corners = SquareSet(0x8100000000000081);
  static const center = SquareSet(0x0000001818000000);
  static const backranks = SquareSet(0xff000000000000ff);
  static const firstRank = SquareSet(0xff);
  static const eighthRank = SquareSet(0xff00000000000000);
  static const aFile = SquareSet(0x0101010101010101);
  static const hFile = SquareSet(0x8080808080808080);

  /// Bitwise right shift
  SquareSet shr(int shift) {
    if (shift >= 64) return SquareSet.empty;
    if (shift > 0) return SquareSet(value >>> shift);
    return this;
  }

  /// Bitwise left shift
  SquareSet shl(int shift) {
    if (shift >= 64) return SquareSet.empty;
    if (shift > 0) return SquareSet(value << shift);
    return this;
  }

  /// Returns a new [SquareSet] with a bitwise XOR of this set and [other].
  SquareSet xor(SquareSet other) => SquareSet(value ^ other.value);
  SquareSet operator ^(SquareSet other) => SquareSet(value ^ other.value);

  /// Returns a new [SquareSet] with the squares that are in either this set or [other].
  SquareSet union(SquareSet other) => SquareSet(value | other.value);
  SquareSet operator |(SquareSet other) => SquareSet(value | other.value);

  /// Returns a new [SquareSet] with the squares that are in both this set and [other].
  SquareSet intersect(SquareSet other) => SquareSet(value & other.value);
  SquareSet operator &(SquareSet other) => SquareSet(value & other.value);

  /// Returns a new [SquareSet] with the [other] squares removed from this set.
  SquareSet minus(SquareSet other) => SquareSet(value - other.value);
  SquareSet operator -(SquareSet other) => SquareSet(value - other.value);

  /// Returns the set complement of this set.
  SquareSet complement() => SquareSet(~value);

  /// Returns the set difference of this set and [other].
  SquareSet diff(SquareSet other) => SquareSet(value & ~other.value);

  /// Flips the set vertically.
  SquareSet flipVertical() {
    const k1 = 0x00FF00FF00FF00FF;
    const k2 = 0x0000FFFF0000FFFF;
    int x = ((value >>> 8) & k1) | ((value & k1) << 8);
    x = ((x >>> 16) & k2) | ((x & k2) << 16);
    x = (x >>> 32) | (x << 32);
    return SquareSet(x);
  }

  /// Flips the set horizontally.
  SquareSet mirrorHorizontal() {
    const k1 = 0x5555555555555555;
    const k2 = 0x3333333333333333;
    const k4 = 0x0f0f0f0f0f0f0f0f;
    int x = ((value >>> 1) & k1) | ((value & k1) << 1);
    x = ((x >>> 2) & k2) | ((x & k2) << 2);
    x = ((x >>> 4) & k4) | ((x & k4) << 4);
    return SquareSet(x);
  }

  /// Returns the number of squares in the set.
  int get size => _popcnt64(value);

  /// Returns true if the set is empty.
  bool get isEmpty => value == 0;

  /// Returns true if the set is not empty.
  bool get isNotEmpty => value != 0;

  /// Returns the first square in the set, or null if the set is empty.
  Square? get first => _getFirstSquare(value);

  /// Returns the last square in the set, or null if the set is empty.
  Square? get last => _getLastSquare(value);

  /// Returns the squares in the set as an iterable.
  Iterable<Square> get squares => _iterateSquares();

  /// Returns the squares in the set as an iterable in reverse order.
  Iterable<Square> get squaresReversed => _iterateSquaresReversed();

  /// Returns true if the set contains more than one square.
  bool get moreThanOne => isNotEmpty && size > 1;

  /// Returns square if it is single, otherwise returns null.
  Square? get singleSquare => moreThanOne ? null : last;

  /// Returns true if the [SquareSet] contains the given [square].
  bool has(Square square) {
    return value & (1 << square) != 0;
  }

  /// Returns true if the square set has any square in the [other] square set.
  bool isIntersected(SquareSet other) => intersect(other).isNotEmpty;

  /// Returns true if the square set is disjoint from the [other] square set.
  bool isDisjoint(SquareSet other) => intersect(other).isEmpty;

  /// Returns a new [SquareSet] with the given [square] added.
  SquareSet withSquare(Square square) {
    return SquareSet(value | (1 << square));
  }

  /// Returns a new [SquareSet] with the given [square] removed.
  SquareSet withoutSquare(Square square) {
    return SquareSet(value & ~(1 << square));
  }

  /// Removes [Square] if present, or put it if absent.
  SquareSet toggleSquare(Square square) {
    return SquareSet(value ^ (1 << square));
  }

  /// Returns a new [SquareSet] with its first [Square] removed.
  SquareSet withoutFirst() {
    final f = first;
    return f != null ? withoutSquare(f) : empty;
  }

  /// Returns the hexadecimal string representation of the bitboard value.
  String toHexString() {
    final buffer = StringBuffer();
    for (int square = 63; square >= 0; square--) {
      buffer.write(has(Square(square)) ? '1' : '0');
    }
    final b = buffer.toString();
    final first = int.parse(b.substring(0, 32), radix: 2)
        .toRadixString(16)
        .toUpperCase()
        .padLeft(8, '0');
    final last = int.parse(b.substring(32, 64), radix: 2)
        .toRadixString(16)
        .toUpperCase()
        .padLeft(8, '0');
    final stringVal = '$first$last';
    if (stringVal == '0000000000000000') {
      return '0';
    }
    return '0x$first$last';
  }

  Iterable<Square> _iterateSquares() sync* {
    int bitboard = value;
    while (bitboard != 0) {
      final square = _getFirstSquare(bitboard);
      bitboard ^= 1 << square!;
      yield square;
    }
  }

  Iterable<Square> _iterateSquaresReversed() sync* {
    int bitboard = value;
    while (bitboard != 0) {
      final square = _getLastSquare(bitboard);
      bitboard ^= 1 << square!;
      yield square;
    }
  }

  Square? _getFirstSquare(int bitboard) {
    final ntz = _ntz64(bitboard);
    return ntz >= 0 && ntz < 64 ? Square(ntz) : null;
  }

  Square? _getLastSquare(int bitboard) {
    if (bitboard == 0) return null;
    return Square(63 - _nlz64(bitboard));
  }
}

int _popcnt64(int n) {
  final count2 = n - ((n >>> 1) & 0x5555555555555555);
  final count4 =
      (count2 & 0x3333333333333333) + ((count2 >>> 2) & 0x3333333333333333);
  final count8 = (count4 + (count4 >>> 4)) & 0x0f0f0f0f0f0f0f0f;
  return (count8 * 0x0101010101010101) >>> 56;
}

int _nlz64(int x) {
  int r = x;
  r |= r >>> 1;
  r |= r >>> 2;
  r |= r >>> 4;
  r |= r >>> 8;
  r |= r >>> 16;
  r |= r >>> 32;
  return 64 - _popcnt64(r);
}

// from https://gist.github.com/jtmcdole/297434f327077dbfe5fb19da3b4ef5be
int _ntz64(int x) => _ntzLut64[(x & -x) % 131];
const _ntzLut64 = [
  64, 0, 1, -1, 2, 46, -1, -1, 3, 14, 47, 56, -1, 18, -1, //
  -1, 4, 43, 15, 35, 48, 38, 57, 23, -1, -1, 19, -1, -1, 51,
  -1, 29, 5, 63, 44, 12, 16, 41, 36, -1, 49, -1, 39, -1, 58,
  60, 24, -1, -1, 62, -1, -1, 20, 26, -1, -1, -1, -1, 52, -1,
  -1, -1, 30, -1, 6, -1, -1, -1, 45, -1, 13, 55, 17, -1, 42,
  34, 37, 22, -1, -1, 50, 28, -1, 11, 40, -1, -1, -1, 59,
  -1, 61, -1, 25, -1, -1, -1, -1, -1, -1, -1, -1, 54, -1,
  33, 21, -1, 27, 10, -1, -1, -1, -1, -1, -1, -1, -1, 53,
  32, -1, 9, -1, -1, -1, -1, 31, 8, -1, -1, 7, -1, -1,
];
