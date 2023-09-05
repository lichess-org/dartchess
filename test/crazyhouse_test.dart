import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';
import 'db_testing_lib.dart';

void main() {
  test('Crazyhouse - issue #23: Crazyhouse en passant bug with DropMove', () {
    Position a = Crazyhouse.initial;
    a = a.playSan('d4');
    a = a.playSan('e5');
    a = a.playSan('Nf3');
    a = a.playSan('Qg5');
    a = a.playSan('Nxg5');
    a = a.playSan('Be7');
    a = a.playSan('dxe5');
    a = a.playSan('Bd8');

    a = a.playSan('Nc3');
    printBoard(a, printLegalMoves: true);

    a = a.playSan('f5'); // creates epSquare at f6 for White
    printBoard(a, printLegalMoves: true);

    a = a.playSan(
        'Q@f7'); // Bug: copyWith() is given null for epSquare, which then copies White's epSquare of f6 forward to Black
    final List<Move> legalMoves = printBoard(a, printLegalMoves: true);
    const MyExpectations myExpectations = MyExpectations(
      legalMoves: 0,
      legalDrops: 0,
      legalDropZone: DropZone.anywhere,
      rolesThatCanDrop: [],
      rolesThatCantDrop: [
        Role.king,
        Role.queen,
        Role.rook,
        Role.bishop,
        Role.knight,
        Role.pawn,
      ],
    );

    expect(myExpectations.testLegalMoves(legalMoves), '');

    expect(a.outcome, Outcome.whiteWins);

    // a = a.playSan('gxf6'); // captures the Queen at f7!
    // printBoard(a, printLegalMoves: true);
  });
}
