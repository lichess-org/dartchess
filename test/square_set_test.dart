import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';
import 'package:dartchess/src/utils.dart';

void main() {
  test('full set has all', () {
    for (int square = 0; square < 64; square++) {
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
    final r = SquareSet(0xe0a12221e222212);
    expect(r.shr(0), r);
    expect(r.shr(1), SquareSet(0x70509110f111109));
    expect(r.shr(3), SquareSet(0x1c1424443c44442));
    expect(r.shr(48), SquareSet(0xe0a));
    expect(r.shr(62), SquareSet(0x0));
  });

  test('shl', () {
    final r = SquareSet(0xe0a12221e222212);
    expect(r.shl(0), r);
    expect(r.shl(1), SquareSet(0x1c1424443c444424));
    expect(r.shl(3), SquareSet(0x70509110f1111090));
    expect(r.shl(10), SquareSet(0x2848887888884800));
    expect(r.shl(32), SquareSet(0x1e22221200000000));
    expect(r.shl(48), SquareSet(0x2212000000000000));
    expect(r.shl(62), SquareSet(0x8000000000000000));
    expect(r.shl(63), SquareSet(0x0));
  });

  test('from file', () {
    expect(SquareSet.fromFile(0), SquareSet(0x0101010101010101));
    expect(SquareSet.fromFile(7), SquareSet(0x8080808080808080));
  });

  test('from rank', () {
    expect(SquareSet.fromRank(0), SquareSet(0x00000000000000FF));
    expect(SquareSet.fromRank(7), SquareSet(0xFF00000000000000));
  });

  test('from square', () {
    expect(SquareSet.fromSquare(42), squareSetFromStringRep('''
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

  test('without square', () {
    expect(squareSetFromStringRep('''
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . 1 1 . . .
. . . 1 1 . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
''').withoutSquare(27), squareSetFromStringRep('''
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

  test('flip vertical', () {
    expect(squareSetFromStringRep('''
. 1 1 1 1 . . .
. 1 . . . 1 . .
. 1 . . . 1 . .
. 1 . . 1 . . .
. 1 1 1 . . . .
. 1 . 1 . . . .
. 1 . . 1 . . .
. 1 . . . 1 . .
''').flipVertical(), squareSetFromStringRep('''
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
    expect(squareSetFromStringRep('''
. 1 1 1 1 . . .
. 1 . . . 1 . .
. 1 . . . 1 . .
. 1 . . 1 . . .
. 1 1 1 . . . .
. 1 . 1 . . . .
. 1 . . 1 . . .
. 1 . . . 1 . .
''').mirrorHorizontal(), squareSetFromStringRep('''
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
