import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';
import 'db_testing_lib.dart';

void main() {
  test('Crazyhouse - dropping queens', () {
    Position a = Crazyhouse.fromSetup(Setup.parseFen(
        'r1bqk2r/pppp1ppp/2n1p3/4P3/1b1Pn3/2NB1N2/PPP2PPP/R1BQK2R[] b KQkq -'));
    List<Move> legalMoves = printBoard(a, printLegalMoves: true);
    MyExpectations myExpectations = const MyExpectations(
        legalMoves: 43,
        legalDrops: 0,
        legalDropZone: DropZone.anywhere,
        rolesThatCanDrop: [],
        rolesThatCantDrop: [
          Role.knight,
          Role.bishop,
          Role.rook,
          Role.king,
          Role.pawn,
          Role.queen
        ]);
    expect(myExpectations.testLegalMoves(legalMoves), '');

    a = a.playSan('Qh4');

    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 31,
        legalDrops: 0,
        legalDropZone: DropZone.anywhere,
        rolesThatCanDrop: [],
        rolesThatCantDrop: [
          Role.knight,
          Role.bishop,
          Role.rook,
          Role.king,
          Role.pawn,
          Role.queen
        ]);
    expect(myExpectations.testLegalMoves(legalMoves), '');

    a = a.playSan('Nxh4');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 41,
        legalDrops: 0,
        legalDropZone: DropZone.anywhere,
        rolesThatCanDrop: [],
        rolesThatCantDrop: [
          Role.knight,
          Role.bishop,
          Role.rook,
          Role.king,
          Role.pawn,
          Role.queen
        ]);
    expect(myExpectations.testLegalMoves(legalMoves), '');

    a = a.playSan('Nxe5');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 36,
        legalDrops: 34,
        legalDropZone: DropZone.anywhere,
        rolesThatCanDrop: [
          Role.queen,
        ],
        rolesThatCantDrop: [
          Role.knight,
          Role.bishop,
          Role.rook,
          Role.king,
          Role.pawn,
        ]);
    expect(myExpectations.testLegalMoves(legalMoves), '');
  });
}
