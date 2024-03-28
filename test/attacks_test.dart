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
    expect(kingAttacks(21), attacks);
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
    expect(kingAttacks(7), attacks);
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
    expect(knightAttacks(35), attacks);
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
    expect(knightAttacks(14), attacks);
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
    expect(pawnAttacks(Side.white, 11), attacks);
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
    expect(pawnAttacks(Side.white, 8), attacks);
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
    expect(pawnAttacks(Side.black, 36), attacks);
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
    expect(pawnAttacks(Side.black, 39), attacks);
  });

  test('Bishop attacks, empty board', () {
    expect(bishopAttacks(27, SquareSet.empty), makeSquareSet('''
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
    expect(bishopAttacks(0, occupied), makeSquareSet('''
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
    expect(bishopAttacks(36, occupied), makeSquareSet('''
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
    expect(rookAttacks(10, SquareSet.empty), makeSquareSet('''
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
    expect(rookAttacks(42, occupied), makeSquareSet('''
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
    expect(rookAttacks(36, occupied), makeSquareSet('''
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
    expect(queenAttacks(37, SquareSet.empty), makeSquareSet('''
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
    expect(queenAttacks(42, occupied), makeSquareSet('''
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
    expect(queenAttacks(36, occupied), makeSquareSet('''
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
      kingAttacks(illegalBoardPosition);
    }, throwsA(isA<AssertionError>()));

    expect(() {
      pawnAttacks(Side.white, illegalBoardPosition);
    }, throwsA(isA<AssertionError>()));

    expect(() {
      knightAttacks(illegalBoardPosition);
    }, throwsA(isA<AssertionError>()));

    expect(() {
      bishopAttacks(illegalBoardPosition, emptySquareSet);
    }, throwsA(isA<AssertionError>()));

    expect(() {
      rookAttacks(illegalBoardPosition, emptySquareSet);
    }, throwsA(isA<AssertionError>()));

    expect(() {
      queenAttacks(illegalBoardPosition, emptySquareSet);
    }, throwsA(isA<AssertionError>()));
  });
}
