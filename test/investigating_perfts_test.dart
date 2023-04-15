import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';
import 'db_testing_lib.dart';

void main() {
  test('Crazyhouse - en passant', () {
    Position a = Crazyhouse.fromSetup(Setup.parseFen(
        'r1bqk2r/pppp1ppp/2n1p3/4P3/1b1Pn3/2NB1N2/PPP2PPP/R1BQK2R b KQkq -'));
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

    a = a.playSan('f5');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 33,
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

    a = a.playSan('exf6');
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
  });

  test('Crazyhouse - dropping a queen', () {
    Position a = Crazyhouse.fromSetup(Setup.parseFen(
        'r1bqk2r/pppp1ppp/2n1p3/4P3/1b1Pn3/2NB1N2/PPP2PPP/R1BQK2R b KQkq -'));
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

    a = a.playSan('Q@d6');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 36,
        legalDrops: 26,
        legalDropZone: DropZone.anywhere,
        rolesThatCanDrop: [
          Role.pawn,
        ],
        rolesThatCantDrop: [
          Role.knight,
          Role.bishop,
          Role.rook,
          Role.king,
          Role.queen
        ]);
    expect(myExpectations.testLegalMoves(legalMoves), '');

    a = a.playSan('P@d2');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 4,
        legalDrops: 0,
        legalDropZone: DropZone.anywhere,
        rolesThatCanDrop: [],
        rolesThatCantDrop: [
          Role.knight,
          Role.bishop,
          Role.rook,
          Role.king,
          Role.pawn,
          Role.queen,
        ]);
    expect(myExpectations.testLegalMoves(legalMoves), '');
  });

  test('Crazyhouse - O-O-O', () {
    Position a = Crazyhouse.fromSetup(Setup.parseFen(
        'r1bqk2r/pppp1ppp/2n1p3/4P3/1b1Pn3/2NB1N2/PPP2PPP/R1BQK2R b KQkq -'));
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

    a = a.playSan('Nd2');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 35,
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

    a = a.playSan('Bxd2');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 35,
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

    a = a.playSan('O-O');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 42,
        legalDrops: 33,
        legalDropZone: DropZone.anywhere,
        rolesThatCanDrop: [
          Role.knight,
        ],
        rolesThatCantDrop: [
          Role.bishop,
          Role.rook,
          Role.king,
          Role.pawn,
          Role.queen
        ]);
    expect(myExpectations.testLegalMoves(legalMoves), '');

    a = a.playSan('Qe2');
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

    a = a.playSan('Re8');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 44,
        legalDrops: 33,
        legalDropZone: DropZone.anywhere,
        rolesThatCanDrop: [
          Role.knight,
        ],
        rolesThatCantDrop: [
          Role.bishop,
          Role.rook,
          Role.king,
          Role.pawn,
          Role.queen
        ]);
    expect(myExpectations.testLegalMoves(legalMoves), '');

    a = a.playSan('O-O-O');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 33,
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
  });

  test('Crazyhouse - move king out and back, then castle', () {
    Position a = Crazyhouse.fromSetup(Setup.parseFen(
        'r1bqk2r/pppp1ppp/2n1p3/4P3/1b1Pn3/2NB1N2/PPP2PPP/R1BQK2R b KQkq -'));
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

    a = a.playSan('Ke7');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 32,
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

    a = a.playSan('Ke2');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 38,
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

    a = a.playSan('Ke8');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 38,
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

    a = a.playSan('Ke1');
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

    a = a.playSan('Ke7'); // tried O-O, but it was threw an exception
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 30,
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

    a = a.playSan('Ke2'); // tried O-O, but it was threw an exception
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 38,
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
  });

  test('Crazyhouse - move rook out and back, then castle', () {
    Position a = Crazyhouse.fromSetup(Setup.parseFen(
        'r1bqk2r/pppp1ppp/2n1p3/4P3/1b1Pn3/2NB1N2/PPP2PPP/R1BQK2R b KQkq -'));
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

    a = a.playSan('Rg8');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 32,
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

    a = a.playSan('Rg1');
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

    a = a.playSan('Rh8');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 29,
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

    a = a.playSan('Rh1');
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

    a = a.playSan('Kf8'); // tried O-O, but it was threw an exception
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 30,
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

    a = a.playSan('Kf1'); // tried O-O, but it was threw an exception
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
  });

  test('Crazyhouse - drop queen for checkmate', () {
    Position a = Crazyhouse.fromSetup(Setup.parseFen(
        'r1bqk2r/pppp1ppp/2n1p3/4P3/1b1Pn3/2NB1N2/PPP2PPP/R1BQK2R b KQkq -'));
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

    a = a.playSan('Qg5');
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

    a = a.playSan('Nxg5');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 40,
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

    a = a.playSan('f5');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 38,
        legalDrops: 33,
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

    a = a.playSan('Q@f7');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 1,
        legalDrops: 0,
        legalDropZone: DropZone.anywhere,
        rolesThatCanDrop: [],
        rolesThatCantDrop: [
          Role.knight,
          Role.bishop,
          Role.rook,
          Role.king,
          Role.pawn,
          Role.queen,
        ]);
    expect(myExpectations.testLegalMoves(legalMoves), '');

    a = a.playSan('Kd8');
    legalMoves = printBoard(a, printLegalMoves: true);
    myExpectations = const MyExpectations(
        legalMoves: 47,
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
  });
}
