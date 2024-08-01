import 'package:test/test.dart';
import 'package:dartchess/dartchess.dart';

void main() {
  test('King attacks', () {
    final attacks = makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . 1 1 1 .
. . . . 1 . 1 .
. . . . 1 1 1 .
. . . . . . . .
''');
    expect(kingAttacks(Square.f3), attacks);
  });

  test('King attacks near edges', () {
    final attacks = makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . 1 1
. . . . . . 1 .
''');
    expect(kingAttacks(Square.h1), attacks);
  });

  test('Knight attacks', () {
    final attacks = makeSquareSet('''
. . . . . . . .
. . 1 . 1 . . .
. 1 . . . 1 . .
. . . . . . . .
. 1 . . . 1 . .
. . 1 . 1 . . .
. . . . . . . .
. . . . . . . .
''');
    expect(knightAttacks(Square.d5), attacks);
  });

  test('Knight attacks near edges', () {
    final attacks = makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . 1 . 1
. . . . 1 . . .
. . . . . . . .
. . . . 1 . . .
''');
    expect(knightAttacks(Square.g2), attacks);
  });

  test('White pawn attacks', () {
    final attacks = makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . 1 . 1 . . .
. . . . . . . .
. . . . . . . .
''');
    expect(pawnAttacks(Side.white, Square.d2), attacks);
  });

  test('White pawn attacks near edges', () {
    final attacks = makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. 1 . . . . . .
. . . . . . . .
. . . . . . . .
''');
    expect(pawnAttacks(Side.white, Square.a2), attacks);
  });

  test('Black pawn attacks', () {
    final attacks = makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . 1 . 1 . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
''');
    expect(pawnAttacks(Side.black, Square.e5), attacks);
  });

  test('Black pawn attacks near edges', () {
    final attacks = makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . 1 .
. . . . . . . .
. . . . . . . .
. . . . . . . .
''');
    expect(pawnAttacks(Side.black, Square.h5), attacks);
  });

  test('Bishop attacks, empty board', () {
    expect(bishopAttacks(Square.d4, SquareSet.empty), makeSquareSet('''
. . . . . . . 1
1 . . . . . 1 .
. 1 . . . 1 . .
. . 1 . 1 . . .
. . . . . . . .
. . 1 . 1 . . .
. 1 . . . 1 . .
1 . . . . . 1 .
'''));
  });

  test('bishop attacks, occupied board', () {
    final occupied = makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . . . 1 . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
''');
    expect(bishopAttacks(Square.a1, occupied), makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . . . 1 . .
. . . . 1 . . .
. . . 1 . . . .
. . 1 . . . . .
. 1 . . . . . .
. . . . . . . .
'''));
  });

  test('Bishop attacks, surrounded in occupied board', () {
    final occupied = makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . 1 1 1 . .
. . . 1 . 1 . .
. . . 1 1 1 . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
''');
    expect(bishopAttacks(Square.e5, occupied), makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . 1 . 1 . .
. . . . . . . .
. . . 1 . 1 . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
'''));
  });

  test('Rook attacks, empty board', () {
    expect(rookAttacks(Square.c2, SquareSet.empty), makeSquareSet('''
. . 1 . . . . .
. . 1 . . . . .
. . 1 . . . . .
. . 1 . . . . .
. . 1 . . . . .
. . 1 . . . . .
1 1 . 1 1 1 1 1
. . 1 . . . . .
'''));
  });

  test('Rook attacks, occupied board', () {
    final occupied = makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . . . 1 . .
. . 1 . . . . .
. . . . . . . .
. . . . . . . .
. . 1 . . . . .
. . . . . . . .
''');
    expect(rookAttacks(Square.c6, occupied), makeSquareSet('''
. . 1 . . . . .
. . 1 . . . . .
1 1 . 1 1 1 . .
. . 1 . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
'''));
  });

  test('Rook attacks, surrounded in occupied board', () {
    final occupied = makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . 1 1 1 . .
. . . 1 . 1 . .
. . . 1 1 1 . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
''');
    expect(rookAttacks(Square.e5, occupied), makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . . 1 . . .
. . . 1 . 1 . .
. . . . 1 . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
'''));
  });

  test('Queen attacks, empty board', () {
    expect(queenAttacks(Square.f5, SquareSet.empty), makeSquareSet('''
. . 1 . . 1 . .
. . . 1 . 1 . 1
. . . . 1 1 1 .
1 1 1 1 1 . 1 1
. . . . 1 1 1 .
. . . 1 . 1 . 1
. . 1 . . 1 . .
. 1 . . . 1 . .
'''));
  });

  test('Queen attacks, occupied board', () {
    final occupied = makeSquareSet('''
. . . . . . . .
. . . . . . . .
. 1 . . . . . .
. . 1 . . . . .
. . . . . . . .
. . . . . 1 . .
. . 1 . . . . .
. . . . . . . .
''');
    expect(queenAttacks(Square.c6, occupied), makeSquareSet('''
1 . 1 . 1 . . .
. 1 1 1 . . . .
. 1 . 1 1 1 1 1
. 1 1 1 . . . .
1 . . . 1 . . .
. . . . . 1 . .
. . . . . . . .
. . . . . . . .
'''));
  });

  test('Queen attacks, surrounded in occupied board', () {
    final occupied = makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . 1 1 1 . .
. . . 1 . 1 . .
. . . 1 1 1 . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
''');
    expect(queenAttacks(Square.e5, occupied), makeSquareSet('''
. . . . . . . .
. . . . . . . .
. . . 1 1 1 . .
. . . 1 . 1 . .
. . . 1 1 1 . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
'''));
  });

  test('Legal board position asserts for attacks', () {
    const illegalBoardPosition = 65;
    const emptySquareSet = SquareSet.empty;

    expect(() {
      kingAttacks(Square(illegalBoardPosition));
    }, throwsA(isA<AssertionError>()));

    expect(() {
      pawnAttacks(Side.white, Square(illegalBoardPosition));
    }, throwsA(isA<AssertionError>()));

    expect(() {
      knightAttacks(Square(illegalBoardPosition));
    }, throwsA(isA<AssertionError>()));

    expect(() {
      bishopAttacks(Square(illegalBoardPosition), emptySquareSet);
    }, throwsA(isA<AssertionError>()));

    expect(() {
      rookAttacks(Square(illegalBoardPosition), emptySquareSet);
    }, throwsA(isA<AssertionError>()));

    expect(() {
      queenAttacks(Square(illegalBoardPosition), emptySquareSet);
    }, throwsA(isA<AssertionError>()));
  });
}
