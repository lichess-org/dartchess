import 'package:test/test.dart';
import 'package:dartchess/dartchess.dart';

void main() {
  test('makeSquareSet', () {
    const rep = '''
. 1 1 1 . . . .
. 1 . 1 . . . .
. 1 . . 1 . . .
. 1 . . . 1 . .
. 1 1 1 1 . . .
. 1 . . . 1 . .
. 1 . . . 1 . .
. 1 . . 1 . . .
''';
    final sq = makeSquareSet(rep);

    expect(rep, humanReadableSquareSet(sq));
    expect(makeSquareSet('''
. . . . . . . 1
. . . . . . 1 .
. . . . . 1 . .
. . . . 1 . . .
. . . 1 . . . .
. . 1 . . . . .
. 1 . . . . . .
1 . . . . . . .
'''), SquareSet.diagonal);
  });

  test('humanReadableBoard', () {
    expect(humanReadableBoard(Board.standard), '''
r n b q k b n r
p p p p p p p p
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
P P P P P P P P
R N B Q K B N R
''');
  });
}
