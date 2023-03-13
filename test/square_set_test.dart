import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';

void main() {
  test('toString', () {
    expect(SquareSet.empty.toString(), 'SquareSet(0)');
    expect(SquareSet.full.toString(), 'SquareSet(0xFFFFFFFFFFFFFFFF)');
    expect(SquareSet.lightSquares.toString(), 'SquareSet(0x55AA55AA55AA55AA)');
    expect(SquareSet.darkSquares.toString(), 'SquareSet(0xAA55AA55AA55AA55)');
    expect(SquareSet.diagonal.toString(), 'SquareSet(0x8040201008040201)');
    expect(SquareSet.antidiagonal.toString(), 'SquareSet(0x0102040810204080)');
    expect(SquareSet.corners.toString(), 'SquareSet(0x8100000000000081)');
    expect(SquareSet.backranks.toString(), 'SquareSet(0xFF000000000000FF)');
    expect(const SquareSet(0x0000000000000001).toString(),
        'SquareSet(0x0000000000000001)');
    expect(const SquareSet(0xf).toString(), 'SquareSet(0x000000000000000F)');
  });

  test('full set has all', () {
    for (Square square = 0; square < 64; square++) {
      expect(SquareSet.full.has(square), true);
    }
  });

  test('size', () {
    SquareSet squares = SquareSet.empty;
    for (int i = 0; i < 64; i++) {
      expect(squares.size, i);
      squares = squares.withSquare(i);
    }
  });

  test('shr', () {
    const r = SquareSet(0xe0a12221e222212);
    expect(r.shr(0), r);
    expect(r.shr(1), const SquareSet(0x70509110f111109));
    expect(r.shr(3), const SquareSet(0x1c1424443c44442));
    expect(r.shr(48), const SquareSet(0xe0a));
    expect(r.shr(62), SquareSet.empty);
  });

  test('shl', () {
    const r = SquareSet(0xe0a12221e222212);
    expect(r.shl(0), r);
    expect(r.shl(1), const SquareSet(0x1c1424443c444424));
    expect(r.shl(3), const SquareSet(0x70509110f1111090));
    expect(r.shl(10), const SquareSet(0x2848887888884800));
    expect(r.shl(32), const SquareSet(0x1e22221200000000));
    expect(r.shl(48), const SquareSet(0x2212000000000000));
    expect(r.shl(62), const SquareSet(0x8000000000000000));
    expect(r.shl(63), SquareSet.empty);
  });

  test('first', () {
    for (Square square = 0; square < 64; square++) {
      expect(SquareSet.fromSquare(square).first, square);
    }
    expect(SquareSet.full.first, 0);
    expect(SquareSet.empty.first, null);
    for (int rank = 0; rank < 8; rank++) {
      expect(SquareSet.fromRank(rank).first, rank * 8);
    }
  });

  test('last', () {
    for (Square square = 0; square < 64; square++) {
      expect(SquareSet.fromSquare(square).last, square);
    }
    expect(SquareSet.full.last, 63);
    expect(SquareSet.empty.last, null);
    for (int rank = 0; rank < 8; rank++) {
      expect(SquareSet.fromRank(rank).last, rank * 8 + 7);
    }
  });

  test('more that one', () {
    expect(SquareSet.empty.moreThanOne, false);
    expect(SquareSet.full.moreThanOne, true);
    expect(const SquareSet.fromSquare(4).moreThanOne, false);
    expect(const SquareSet.fromSquare(4).withSquare(5).moreThanOne, true);
  });

  test('singleSquare', () {
    expect(SquareSet.empty.singleSquare, null);
    expect(SquareSet.full.singleSquare, null);
    expect(const SquareSet.fromSquare(4).singleSquare, 4);
    expect(const SquareSet.fromSquare(4).withSquare(5).singleSquare, null);
  });

  test('squares', () {
    expect(SquareSet.empty.squares.toList(), List<Square>.empty());
    expect(SquareSet.full.squares.toList(), [for (int i = 0; i < 64; i++) i]);
    expect(SquareSet.diagonal.squares, equals([0, 9, 18, 27, 36, 45, 54, 63]));
  });

  test('squaresReversed', () {
    expect(SquareSet.empty.squaresReversed.toList(), List<Square>.empty());
    expect(SquareSet.full.squaresReversed.toList(),
        [for (int i = 63; i >= 0; i--) i]);
    expect(SquareSet.diagonal.squaresReversed,
        equals([63, 54, 45, 36, 27, 18, 9, 0]));
  });

  test('from file', () {
    expect(const SquareSet.fromFile(0), const SquareSet(0x0101010101010101));
    expect(const SquareSet.fromFile(7), const SquareSet(0x8080808080808080));
  });

  test('from rank', () {
    expect(const SquareSet.fromRank(0), const SquareSet(0x00000000000000FF));
    expect(const SquareSet.fromRank(7), const SquareSet(0xFF00000000000000));
  });

  test('from square', () {
    expect(const SquareSet.fromSquare(42), makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . 1 . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
'''));
  });

  test('from squares', () {
    expect(SquareSet.fromSquares(const [42, 44, 26, 28]), makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . 1 . 1 . . .
. . . . . . . .
. . 1 . 1 . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
'''));
  });

  test('with square', () {
    expect(SquareSet.center.withSquare(43), makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . 1 . . . .
. . . 1 1 . . .
. . . 1 1 . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
'''));
  });

  test('without square', () {
    expect(SquareSet.center.withoutSquare(27), makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . 1 1 . . .
. . . . 1 . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
'''));
  });

  test('toggle square', () {
    expect(SquareSet.center.toggleSquare(35).toggleSquare(43), makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . 1 . . . .
. . . . 1 . . .
. . . 1 1 . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
'''));
  });

  test('flip vertical', () {
    expect(makeSquareSet('''
. 1 1 1 1 . . .
. 1 . . . 1 . .
. 1 . . . 1 . .
. 1 . . 1 . . .
. 1 1 1 . . . .
. 1 . 1 . . . .
. 1 . . 1 . . .
. 1 . . . 1 . .
''').flipVertical(), makeSquareSet('''
. 1 . . . 1 . .
. 1 . . 1 . . .
. 1 . 1 . . . .
. 1 1 1 . . . .
. 1 . . 1 . . .
. 1 . . . 1 . .
. 1 . . . 1 . .
. 1 1 1 1 . . .
'''));
  });

  test('mirror horizontal', () {
    expect(makeSquareSet('''
. 1 1 1 1 . . .
. 1 . . . 1 . .
. 1 . . . 1 . .
. 1 . . 1 . . .
. 1 1 1 . . . .
. 1 . 1 . . . .
. 1 . . 1 . . .
. 1 . . . 1 . .
''').mirrorHorizontal(), makeSquareSet('''
. . . 1 1 1 1 .
. . 1 . . . 1 .
. . 1 . . . 1 .
. . . 1 . . 1 .
. . . . 1 1 1 .
. . . . 1 . 1 .
. . . 1 . . 1 .
. . 1 . . . 1 .
'''));
  });
}
