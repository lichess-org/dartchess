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

  test('bishop attacks, empty board', () {
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

  test('rook attacks, empty board', () {
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

  test('rook attacks, occupied board', () {
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

  test('queen attacks, empty board', () {
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

  test('queen attacks, occupied board', () {
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
}
