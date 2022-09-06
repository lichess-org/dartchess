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
    print(sq);

    expect(rep, printSquareSet(sq));
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
}
