import 'package:test/test.dart';
import 'package:dartchess/src/utils.dart';

void main() {
  test('squareSetFromStringRep', () {
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
    final sq = squareSetFromStringRep(rep);

    expect(rep, sq.debugPrint());
  });
}
