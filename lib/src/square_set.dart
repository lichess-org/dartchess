import 'package:meta/meta.dart';
import './models.dart';

/// A set of squares represented by a 64 bit integer mask, using little endian
/// rank-file (LERF) mapping.
///
/// ```
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
/// ```
@immutable
class SquareSet {
  /// Creates a [SquareSet] with the provided 64bit integer value.
  const SquareSet(this.value);

  /// Creates a [SquareSet] with a single [Square].
  const SquareSet.fromSquare(Square square)
      : value = 1 << square,
        assert(square >= 0 && square < 64);

  /// Creates a [SquareSet] from several [Square]s.
  SquareSet.fromSquares(Iterable<Square> squares)
      : value = squares
            .map((square) => 1 << square)
            .fold(0, (left, right) => left | right);

  /// Create a [SquareSet] containing all squares of the given rank.
  const SquareSet.fromRank(int rank)
      : value = 0xff << (8 * rank),
        assert(rank >= 0 && rank < 8);

  /// Create a [SquareSet] containing all squares of the given file.
  const SquareSet.fromFile(int file)
      : value = 0x0101010101010101 << file,
        assert(file >= 0 && file < 8);

  /// Create a [SquareSet] containing all squares of the given backrank [Side].
  const SquareSet.backrankOf(Side side)
      : value = side == Side.white ? 0xff : 0xff00000000000000;

  /// 64 bit integer representing the square set.
  final int value;

  static const empty = SquareSet(0);
  static const full = SquareSet(0xffffffffffffffff);
  static const lightSquares = SquareSet(0x55AA55AA55AA55AA);
  static const darkSquares = SquareSet(0xAA55AA55AA55AA55);
  static const diagonal = SquareSet(0x8040201008040201);
  static const antidiagonal = SquareSet(0x0102040810204080);
  static const corners = SquareSet(0x8100000000000081);
  static const center = SquareSet(0x0000001818000000);
  static const backranks = SquareSet(0xff000000000000ff);

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

  SquareSet xor(SquareSet other) => SquareSet(value ^ other.value);
  SquareSet operator ^(SquareSet other) => SquareSet(value ^ other.value);

  SquareSet union(SquareSet other) => SquareSet(value | other.value);
  SquareSet operator |(SquareSet other) => SquareSet(value | other.value);

  SquareSet intersect(SquareSet other) => SquareSet(value & other.value);
  SquareSet operator &(SquareSet other) => SquareSet(value & other.value);

  SquareSet minus(SquareSet other) => SquareSet(value - other.value);
  SquareSet operator -(SquareSet other) => SquareSet(value - other.value);

  SquareSet complement() => SquareSet(~value);

  SquareSet diff(SquareSet other) => SquareSet(value & ~other.value);

  SquareSet flipVertical() {
    const k1 = 0x00FF00FF00FF00FF;
    const k2 = 0x0000FFFF0000FFFF;
    int x = ((value >>> 8) & k1) | ((value & k1) << 8);
    x = ((x >>> 16) & k2) | ((x & k2) << 16);
    x = (x >>> 32) | (x << 32);
    return SquareSet(x);
  }

  SquareSet mirrorHorizontal() {
    const k1 = 0x5555555555555555;
    const k2 = 0x3333333333333333;
    const k4 = 0x0f0f0f0f0f0f0f0f;
    int x = ((value >>> 1) & k1) | ((value & k1) << 1);
    x = ((x >>> 2) & k2) | ((x & k2) << 2);
    x = ((x >>> 4) & k4) | ((x & k4) << 4);
    return SquareSet(x);
  }

  int get size => _popcnt64(value);
  bool get isEmpty => value == 0;
  bool get isNotEmpty => value != 0;
  int? get first => _getFirstSquare(value);
  int? get last => _getLastSquare(value);
  Iterable<Square> get squares => _iterateSquares();
  Iterable<Square> get squaresReversed => _iterateSquaresReversed();
  bool get moreThanOne => isNotEmpty && size > 1;

  /// Returns square if it is single, otherwise returns null.
  int? get singleSquare => moreThanOne ? null : last;

  bool has(Square square) {
    assert(square >= 0 && square < 64);
    return value & (1 << square) != 0;
  }

  bool isIntersected(SquareSet other) => intersect(other).isNotEmpty;
  bool isDisjoint(SquareSet other) => intersect(other).isEmpty;

  SquareSet withSquare(Square square) {
    assert(square >= 0 && square < 64);
    return SquareSet(value | (1 << square));
  }

  SquareSet withoutSquare(Square square) {
    assert(square >= 0 && square < 64);
    return SquareSet(value & ~(1 << square));
  }

  /// Removes [Square] if present, or put it if absent.
  SquareSet toggleSquare(Square square) {
    assert(square >= 0 && square < 64);
    return SquareSet(value ^ (1 << square));
  }

  SquareSet withoutFirst() {
    final f = first;
    return f != null ? withoutSquare(f) : empty;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SquareSet &&
            other.runtimeType == runtimeType &&
            other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    final buffer = StringBuffer();
    for (Square square = 63; square >= 0; square--) {
      buffer.write(has(square) ? '1' : '0');
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
      return 'SquareSet(0)';
    }
    return 'SquareSet(0x$first$last)';
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

  int? _getFirstSquare(int bitboard) {
    final ntz = _ntz64(bitboard);
    return ntz >= 0 && ntz < 64 ? ntz : null;
  }

  int? _getLastSquare(int bitboard) {
    if (bitboard == 0) return null;
    return 63 - _nlz64(bitboard);
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
