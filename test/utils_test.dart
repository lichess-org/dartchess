import 'package:test/test.dart';
import 'package:dartchess/src/utils.dart';

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

    expect(rep, printSquareSet(sq));
  });
}
