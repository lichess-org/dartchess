import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';

void main() {
  group('SquareSet', () {
    test('toHexString', () {
      expect(SquareSet.empty.toHexString(), '0');
      expect(SquareSet.full.toHexString(), '0xFFFFFFFFFFFFFFFF');
      expect(SquareSet.lightSquares.toHexString(), '0x55AA55AA55AA55AA');
      expect(SquareSet.darkSquares.toHexString(), '0xAA55AA55AA55AA55');
      expect(SquareSet.diagonal.toHexString(), '0x8040201008040201');
      expect(SquareSet.antidiagonal.toHexString(), '0x0102040810204080');
      expect(SquareSet.corners.toHexString(), '0x8100000000000081');
      expect(SquareSet.backranks.toHexString(), '0xFF000000000000FF');
      expect(const SquareSet(0x0000000000000001).toHexString(),
          '0x0000000000000001');
      expect(const SquareSet(0xf).toHexString(), '0x000000000000000F');
    });

    test('full set has all', () {
      for (int i = 0; i < 64; i++) {
        expect(SquareSet.full.has(Square(i)), true);
      }
    });

    test('size', () {
      SquareSet squares = SquareSet.empty;
      for (int i = 0; i < 64; i++) {
        expect(squares.size, i);
        squares = squares.withSquare(Square(i));
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
      for (int i = 0; i < 64; i++) {
        expect(SquareSet.fromSquare(Square(i)).first, Square(i));
      }
      expect(SquareSet.full.first, Square.a1);
      expect(SquareSet.empty.first, null);
      for (int rank = 0; rank < 8; rank++) {
        expect(SquareSet.fromRank(Rank(rank)).first, Square(rank * 8));
      }
    });

    test('last', () {
      for (int i = 0; i < 64; i++) {
        expect(SquareSet.fromSquare(Square(i)).last, Square(i));
      }
      expect(SquareSet.full.last, Square.h8);
      expect(SquareSet.empty.last, null);
      for (int rank = 0; rank < 8; rank++) {
        expect(SquareSet.fromRank(Rank(rank)).last, Square(rank * 8 + 7));
      }
    });

    test('more that one', () {
      expect(SquareSet.empty.moreThanOne, false);
      expect(SquareSet.full.moreThanOne, true);
      expect(const SquareSet.fromSquare(Square.e1).moreThanOne, false);
      expect(
          const SquareSet.fromSquare(Square.e1)
              .withSquare(Square.f1)
              .moreThanOne,
          true);
    });

    test('singleSquare', () {
      expect(SquareSet.empty.singleSquare, null);
      expect(SquareSet.full.singleSquare, null);
      expect(const SquareSet.fromSquare(Square.e1).singleSquare, Square.e1);
      expect(
          const SquareSet.fromSquare(Square.e1)
              .withSquare(Square.f1)
              .singleSquare,
          null);
    });

    test('squares', () {
      expect(SquareSet.empty.squares.toList(), List<Square>.empty());
      expect(
        SquareSet.full.squares.toList(),
        [for (int i = 0; i < 64; i++) Square(i)],
      );
      expect(
          SquareSet.diagonal.squares,
          equals([
            Square.a1,
            Square.b2,
            Square.c3,
            Square.d4,
            Square.e5,
            Square.f6,
            Square.g7,
            Square.h8,
          ]));
    });

    test('squaresReversed', () {
      expect(SquareSet.empty.squaresReversed.toList(), List<Square>.empty());
      expect(
        SquareSet.full.squaresReversed.toList(),
        [for (int i = 63; i >= 0; i--) Square(i)],
      );
      expect(
          SquareSet.diagonal.squaresReversed,
          equals([
            Square.h8,
            Square.g7,
            Square.f6,
            Square.e5,
            Square.d4,
            Square.c3,
            Square.b2,
            Square.a1,
          ]));
    });

    test('from file', () {
      expect(const SquareSet.fromFile(File(0)),
          const SquareSet(0x0101010101010101));
      expect(const SquareSet.fromFile(File(7)),
          const SquareSet(0x8080808080808080));
    });

    test('from rank', () {
      expect(const SquareSet.fromRank(Rank(0)),
          const SquareSet(0x00000000000000FF));
      expect(const SquareSet.fromRank(Rank(7)),
          const SquareSet(0xFF00000000000000));
    });

    test('from square', () {
      expect(const SquareSet.fromSquare(Square.c6), makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . 1 . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
'''));

      expect(const SquareSet.fromSquare(Square.a1), const SquareSet(1));
      expect(const SquareSet.fromSquare(Square.h8),
          const SquareSet(0x8000000000000000));
    });

    test('from squares', () {
      expect(
          SquareSet.fromSquares(
              const [Square.c6, Square.e6, Square.c4, Square.e4]),
          makeSquareSet('''
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
      expect(SquareSet.center.withSquare(Square.d6), makeSquareSet('''
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
      expect(SquareSet.center.withoutSquare(Square.d4), makeSquareSet('''
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
      expect(SquareSet.center.toggleSquare(Square.d5).toggleSquare(Square.d6),
          makeSquareSet('''
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
  });
}
