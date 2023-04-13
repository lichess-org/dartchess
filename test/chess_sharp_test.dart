import 'dart:io';

import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';

void main() {
  const verbosePrinting = false;
  void conditionalPrint(Object? a) {
    if (verbosePrinting) print(a);
  }

  void printBoard(Position a, [List<NormalMove>? legalMoves]) {
    if (legalMoves == null) {
      conditionalPrint(humanReadableBoard(a.board, a.pockets));
      return;
    } else {
      conditionalPrint(
          '${humanReadableBoard(a.board, a.pockets)}Legal moves: $legalMoves\n\n\n');
    }
  }

  print(
      '**********\nChess♯ variant\nThe rules for Chess♯ can be found at\nhttps://chess-sharp.games/ChessSharp_Rules.pdf\n\nSet the "verbosePrinting" constant to true (line 7 of chess_sharp_test.dart) to help with debugging these tests\n**********');
  test('Chess♯ - board starts with 16 pawns (only)', () {
    expect(Board.chessSharp.pieces.length, 16);
    expect(Board.chessSharp.materialCount(Side.white)[Role.pawn], 8);
    expect(Board.chessSharp.materialCount(Side.white)[Role.knight], 0);
    expect(Board.chessSharp.materialCount(Side.white)[Role.bishop], 0);
    expect(Board.chessSharp.materialCount(Side.white)[Role.rook], 0);
    expect(Board.chessSharp.materialCount(Side.white)[Role.queen], 0);
    expect(Board.chessSharp.materialCount(Side.white)[Role.king], 0);
    expect(Board.chessSharp.materialCount(Side.black)[Role.pawn], 8);
    expect(Board.chessSharp.materialCount(Side.black)[Role.knight], 0);
    expect(Board.chessSharp.materialCount(Side.black)[Role.bishop], 0);
    expect(Board.chessSharp.materialCount(Side.black)[Role.rook], 0);
    expect(Board.chessSharp.materialCount(Side.black)[Role.queen], 0);
    expect(Board.chessSharp.materialCount(Side.black)[Role.king], 0);
  });
  test('Chess♯ - pockets start with the 16 standard non-pawn pieces', () {
    const myPockets = Pockets.chessSharp;
    expect(myPockets.size, 16);
    expect(myPockets.countSide(Side.white), 8);
    expect(myPockets.countSide(Side.black), 8);
    expect(myPockets.count(Role.pawn), 0);
    expect(myPockets.count(Role.knight), 4);
    expect(myPockets.count(Role.bishop), 4);
    expect(myPockets.count(Role.rook), 4);
    expect(myPockets.count(Role.queen), 2);
    expect(myPockets.count(Role.king), 2);
    expect(myPockets.of(Side.white, Role.pawn), 0);
    expect(myPockets.of(Side.white, Role.knight), 2);
    expect(myPockets.of(Side.white, Role.bishop), 2);
    expect(myPockets.of(Side.white, Role.rook), 2);
    expect(myPockets.of(Side.white, Role.queen), 1);
    expect(myPockets.of(Side.white, Role.king), 1);
    expect(myPockets.of(Side.black, Role.pawn), 0);
    expect(myPockets.of(Side.black, Role.knight), 2);
    expect(myPockets.of(Side.black, Role.bishop), 2);
    expect(myPockets.of(Side.black, Role.rook), 2);
    expect(myPockets.of(Side.black, Role.queen), 1);
    expect(myPockets.of(Side.black, Role.king), 1);
    expect(myPockets.hasQuality(Side.white), true);
    expect(myPockets.hasQuality(Side.black), true);
    expect(myPockets.hasPawn(Side.white), false);
    expect(myPockets.hasPawn(Side.black), false);
    expect(myPockets.toString(), '[NNBBRRKQnnbbrrkq]');
  });
  test('Chess♯ - inital fen', () {
    expect(ChessSharp.initial.fen,
        '8/pppppppp/8/8/8/8/PPPPPPPP/8[NNBBRRKQnnbbrrkq] w - - 0 1');

    final loadedPosition = ChessSharp.fromSetup(Setup.parseFen(
        '8/pppppppp/8/8/8/8/PPPPPPPP/8[NNBBRRKQnnbbrrkq] w - - 0 1'));
    expect(ChessSharp.initial.fen, loadedPosition.fen);
  });
  test('Chess♯ - kingCount', () {
    const ChessSharp a = ChessSharp.initial;
    expect(a.board.kings.size, 0);
    expect(a.pockets!.of(Side.white, Role.king), 1);
    expect(a.pockets!.of(Side.black, Role.king), 1);
  });
  test('Chess♯ - test all legal moves and drops from the beginning', () {
    const noDrops = <int>[];
    final whiteHomeRow = <int>[
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
    ];
    final blackHomeRow = <int>[
      56,
      57,
      58,
      59,
      60,
      61,
      62,
      63,
    ];
    List<int> dropTestEachSquare(Position position, Role pieceRole) {
      final legalDrops = <int>[];
      for (int a = 0; a < 64; a++) {
        if (position.isLegal(DropMove(role: pieceRole, to: a))) {
          legalDrops.add(a);
        }
      }
      return legalDrops;
    }

    List<NormalMove> moveTestEachSquare(Position position) {
      final legalMoves = <NormalMove>[];
      for (int a = 0; a < 64; a++) {
        for (int b = 0; b < 64; b++) {
          if (position.isLegal(NormalMove(from: a, to: b))) {
            legalMoves.add(NormalMove(from: a, to: b));
          }
        }
      }
      return legalMoves;
    }

    Position a = ChessSharp.initial;

    var legalMoves = moveTestEachSquare(a);
    printBoard(a, legalMoves);
    expect(legalMoves.length, 0);

    var legalDrops = dropTestEachSquare(a, Role.pawn);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.knight);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.bishop);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.rook);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.queen);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.king);
    expect(legalDrops, whiteHomeRow);

    a = a.playSan('K@a1');
    whiteHomeRow.remove(0);

    legalMoves = moveTestEachSquare(a);
    printBoard(a, legalMoves);
    expect(legalMoves.length, 0);

    legalDrops = dropTestEachSquare(a, Role.pawn);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.knight);
    expect(legalDrops, blackHomeRow);
    legalDrops = dropTestEachSquare(a, Role.bishop);
    expect(legalDrops, blackHomeRow);
    legalDrops = dropTestEachSquare(a, Role.rook);
    expect(legalDrops, blackHomeRow);
    legalDrops = dropTestEachSquare(a, Role.queen);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.king);
    expect(legalDrops, blackHomeRow);

    a = a.playSan('N@a8');
    blackHomeRow.remove(56);

    legalMoves = moveTestEachSquare(a);
    printBoard(a, legalMoves);
    expect(legalMoves.length, 9);

    legalDrops = dropTestEachSquare(a, Role.pawn);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.knight);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.bishop);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.rook);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.queen);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.king);
    expect(legalDrops, noDrops);

    a = a.playSan('a3');

    legalMoves = moveTestEachSquare(a);
    printBoard(a, legalMoves);
    expect(legalMoves.length, 0);

    legalDrops = dropTestEachSquare(a, Role.pawn);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.knight);
    expect(legalDrops, blackHomeRow);
    legalDrops = dropTestEachSquare(a, Role.bishop);
    expect(legalDrops, blackHomeRow);
    legalDrops = dropTestEachSquare(a, Role.rook);
    expect(legalDrops, blackHomeRow);
    legalDrops = dropTestEachSquare(a, Role.queen);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.king);
    expect(legalDrops, blackHomeRow);

    a = a.playSan('N@b8');
    blackHomeRow.remove(57);

    legalMoves = moveTestEachSquare(a);
    printBoard(a, legalMoves);
    expect(legalMoves.length, 10);

    legalDrops = dropTestEachSquare(a, Role.pawn);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.knight);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.bishop);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.rook);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.queen);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.king);
    expect(legalDrops, noDrops);

    a = a.playSan('b3');

    legalMoves = moveTestEachSquare(a);
    printBoard(a, legalMoves);
    expect(legalMoves.length, 0);

    legalDrops = dropTestEachSquare(a, Role.pawn);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.knight);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.bishop);
    expect(legalDrops, blackHomeRow);
    legalDrops = dropTestEachSquare(a, Role.rook);
    expect(legalDrops, blackHomeRow);
    legalDrops = dropTestEachSquare(a, Role.queen);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.king);
    expect(legalDrops, blackHomeRow);

    a = a.playSan('B@c8');
    blackHomeRow.remove(58);

    legalMoves = moveTestEachSquare(a);
    printBoard(a, legalMoves);
    expect(legalMoves.length, 11);

    legalDrops = dropTestEachSquare(a, Role.pawn);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.knight);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.bishop);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.rook);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.queen);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.king);
    expect(legalDrops, noDrops);

    a = a.playSan('c3');

    legalMoves = moveTestEachSquare(a);
    printBoard(a, legalMoves);
    expect(legalMoves.length, 0);

    legalDrops = dropTestEachSquare(a, Role.pawn);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.knight);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.bishop);
    expect(legalDrops, blackHomeRow);
    legalDrops = dropTestEachSquare(a, Role.rook);
    expect(legalDrops, blackHomeRow);
    legalDrops = dropTestEachSquare(a, Role.queen);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.king);
    expect(legalDrops, blackHomeRow);

    a = a.playSan('B@d8');
    blackHomeRow.remove(59);

    legalMoves = moveTestEachSquare(a);
    printBoard(a, legalMoves);
    expect(legalMoves.length, 11);

    legalDrops = dropTestEachSquare(a, Role.pawn);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.knight);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.bishop);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.rook);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.queen);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.king);
    expect(legalDrops, noDrops);

    a = a.playSan('d3');

    legalMoves = moveTestEachSquare(a);
    printBoard(a, legalMoves);
    expect(legalMoves.length, 0);

    legalDrops = dropTestEachSquare(a, Role.pawn);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.knight);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.bishop);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.rook);
    expect(legalDrops, blackHomeRow);
    legalDrops = dropTestEachSquare(a, Role.queen);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.king);
    expect(legalDrops, blackHomeRow);

    a = a.playSan('R@e8');
    blackHomeRow.remove(60);

    legalMoves = moveTestEachSquare(a);
    printBoard(a, legalMoves);
    expect(legalMoves.length, 11);

    legalDrops = dropTestEachSquare(a, Role.pawn);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.knight);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.bishop);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.rook);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.queen);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.king);
    expect(legalDrops, noDrops);

    a = a.playSan('e3');

    legalMoves = moveTestEachSquare(a);
    printBoard(a, legalMoves);
    expect(legalMoves.length, 0);

    legalDrops = dropTestEachSquare(a, Role.pawn);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.knight);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.bishop);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.rook);
    expect(legalDrops, blackHomeRow);
    legalDrops = dropTestEachSquare(a, Role.queen);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.king);
    expect(legalDrops, blackHomeRow);

    a = a.playSan('R@f8');
    blackHomeRow.remove(61);

    legalMoves = moveTestEachSquare(a);
    printBoard(a, legalMoves);
    expect(legalMoves.length, 11);

    legalDrops = dropTestEachSquare(a, Role.pawn);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.knight);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.bishop);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.rook);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.queen);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.king);
    expect(legalDrops, noDrops);

    a = a.playSan('f3');

    legalMoves = moveTestEachSquare(a);
    printBoard(a, legalMoves);
    expect(legalMoves.length, 0);

    legalDrops = dropTestEachSquare(a, Role.pawn);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.knight);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.bishop);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.rook);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.queen);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.king);
    expect(legalDrops, blackHomeRow);

    a = a.playSan('K@g8');
    blackHomeRow.remove(62);

    legalMoves = moveTestEachSquare(a);
    printBoard(a, legalMoves);
    expect(legalMoves.length, 11);

    legalDrops = dropTestEachSquare(a, Role.pawn);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.knight);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.bishop);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.rook);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.queen);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.king);
    expect(legalDrops, noDrops);

    a = a.playSan('g3');

    legalMoves = moveTestEachSquare(a);
    printBoard(a, legalMoves);
    expect(legalMoves.length, 12); // 8 pawn moves, 1 king, 3 knight

    legalDrops = dropTestEachSquare(a, Role.pawn);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.knight);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.bishop);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.rook);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.queen);
    expect(legalDrops, blackHomeRow);
    legalDrops = dropTestEachSquare(a, Role.king);
    expect(legalDrops, noDrops);

    a = a.playSan('Nb6');
    blackHomeRow
      ..add(56)
      ..sort();

    legalMoves = moveTestEachSquare(a);
    printBoard(a, legalMoves);
    expect(legalMoves.length, 11);

    legalDrops = dropTestEachSquare(a, Role.pawn);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.knight);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.bishop);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.rook);
    expect(legalDrops, whiteHomeRow);
    legalDrops = dropTestEachSquare(a, Role.queen);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.king);
    expect(legalDrops, noDrops);

    a = a.playSan('h3');

    legalMoves = moveTestEachSquare(a);
    printBoard(a, legalMoves);
    expect(legalMoves.length, 14); // 7 pawn moves, 1 king, 6 knight

    legalDrops = dropTestEachSquare(a, Role.pawn);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.knight);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.bishop);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.rook);
    expect(legalDrops, noDrops);
    legalDrops = dropTestEachSquare(a, Role.queen);
    expect(legalDrops, blackHomeRow);
    legalDrops = dropTestEachSquare(a, Role.king);
    expect(legalDrops, noDrops);

    a = a.playSan('Nc6');
    blackHomeRow
      ..add(57)
      ..sort();
  });
  test(
      "Chess♯ - test that when a piece is captured it doesn't enter the pockets (like it does for Crazyhouse)",
      () {
    Position a = ChessSharp.initial;
    a = a.playSan('K@a1');
    a = a.playSan('R@h8');
    a = a.playSan('R@g1');
    expect(a.pockets.toString(), '[NNBBRQnnbbrkq]');
    printBoard(a);
    a = a.playSan('R@g8');
    a = a.playSan('g3');
    expect(a.pockets.toString(), '[NNBBRQnnbbkq]');
    printBoard(a);
    a = a.playSan('B@f8');
    a = a.playSan('g4');
    expect(a.pockets.toString(), '[NNBBRQnnbkq]');
    printBoard(a);
    a = a.playSan('B@e8');
    a = a.playSan('Rg3');
    expect(a.pockets.toString(), '[NNBBRQnnkq]');
    printBoard(a);
    a = a.playSan('N@d8');
    a = a.playSan('Rh3');
    expect(a.pockets.toString(), '[NNBBRQnkq]');
    printBoard(a);
    a = a.playSan('N@c8');
    a = a.playSan('Rxh7');
    expect(a.pockets.toString(), '[NNBBRQkq]');
    printBoard(a);
    a = a.playSan('K@a8');
    a = a.playSan('Rxh8');
    expect(a.pockets.toString(), '[NNBBRQq]');
    printBoard(a);
    a = a.playSan('Q@b8');
    a = a.playSan('Rxg8');
    expect(a.pockets.toString(), '[NNBBRQ]');
    printBoard(a);
    a = a.playSan('a6');
    a = a.playSan('Rxf8');
    expect(a.pockets.toString(), '[NNBBRQ]');
    printBoard(a);
    a = a.playSan('a5');
    a = a.playSan('Rxe8');
    expect(a.pockets.toString(), '[NNBBRQ]');
    printBoard(a);
    a = a.playSan('a4');
    a = a.playSan('Rxd8');
    expect(a.pockets.toString(), '[NNBBRQ]');
    printBoard(a);
    a = a.playSan('a3');
    a = a.playSan('Rxc8');
    expect(a.pockets.toString(), '[NNBBRQ]');
    printBoard(a);
    a = a.playSan('axb2');
    a = a.playSan('Kxb2');
    expect(a.pockets.toString(), '[NNBBRQ]');
    printBoard(a);
    a = a.playSan('c6');
    a = a.playSan('Rxb8');
    expect(a.pockets.toString(), '[NNBBRQ]');
    printBoard(a);
    a = a.playSan('c5');
    a = a.playSan('Rxb7');
    expect(a.pockets.toString(), '[NNBBRQ]');
    printBoard(a);
    a = a.playSan('c4');
    a = a.playSan('Rxd7');
    expect(a.pockets.toString(), '[NNBBRQ]');
    printBoard(a);
    a = a.playSan('c3');
    a = a.playSan('Rxe7');
    expect(a.pockets.toString(), '[NNBBRQ]');
    printBoard(a);
    a = a.playSan('Ka7');
    a = a.playSan('Rxf7');
    expect(a.pockets.toString(), '[NNBBRQ]');
    printBoard(a);
    a = a.playSan('Kb7');
    a = a.playSan('Rxg7');
    expect(a.pockets.toString(), '[NNBBRQ]');
    printBoard(a);
    a = a.playSan('Ka7');
    a = a.playSan('Kxc3');
    expect(a.pockets.toString(), '[NNBBRQ]');
    printBoard(a);
    a = a.playSan('Kb7');
    a = a.playSan('Rxb7');
    expect(a.pockets.toString(), '[NNBBRQ]');
    printBoard(a);
    expect(a.outcome, Outcome.whiteWins);
  });
  test(
      "Chess♯ - test that you can move a pinned piece, move into check, and the game ends when you take the opponent's king\n\t(score for taking a king is 10–0 or 0–10)",
      () {
    Position a = ChessSharp.initial;
    a = a.playSan('K@a1');
    a = a.playSan('K@g8');
    a = a.playSan('B@h1');
    a = a.playSan('B@h8');
    a = a.playSan('B@g1');
    a = a.playSan('g6');
    // moves pinned pawn, exposes king to being taken
    a = a.playSan('b3');
    a = a.playSan('B@f8');
    // moves in check
    a = a.playSan('Kb2');
    // takes king
    a = a.playSan('Bxb2');
    printBoard(a);
    conditionalPrint(a.outcome);
    conditionalPrint(Outcome.toPgnStringChessSharp(a.outcome));
    expect(Outcome.toPgnStringChessSharp(a.outcome), '0–10');
  });
  test('Chess♯ - test dropping a king into check', () {
    Position a = ChessSharp.initial;
    a = a.playSan('K@a1');
    a = a.playSan('N@h8');
    a = a.playSan('B@h1');
    a = a.playSan('N@g8');
    a = a.playSan('g3');
    a = a.playSan('B@f8');
    a = a.playSan('Bxb7');
    a = a.playSan('K@a8');
    a = a.playSan('Bxa8');
    printBoard(a);
    conditionalPrint(a.outcome);
    conditionalPrint(Outcome.toPgnStringChessSharp(a.outcome));
    expect(Outcome.toPgnStringChessSharp(a.outcome), '10–0');
  });
  test('Chess♯ - test that there is no castling', () {
    Position a = ChessSharp.initial;
    a = a.playSan('K@e1');
    a = a.playSan('K@e8');
    a = a.playSan('R@a1');
    a = a.playSan('R@a8');
    a = a.playSan('R@h1');
    a = a.playSan('R@h8');
    expect(() => a.playSan('O-O'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('O-O-O'), throwsA(const TypeMatcher<PlayError>()));
    a = a.playSan('e3');
    expect(() => a.playSan('O-O'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('O-O-O'), throwsA(const TypeMatcher<PlayError>()));
    printBoard(a);
  });
  test('Chess♯ - test that pawns do not sprint', () {
    Position a = ChessSharp.initial;
    a = a.playSan('K@e1');
    a = a.playSan('K@e8');
    expect(() => a.playSan('a4'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('b4'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('c4'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('d4'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('e4'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('f4'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('g4'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('h4'), throwsA(const TypeMatcher<PlayError>()));
    a = a.playSan('a3');
    expect(() => a.playSan('a5'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('b5'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('c5'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('d5'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('e5'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('f5'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('g5'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('h5'), throwsA(const TypeMatcher<PlayError>()));
    conditionalPrint('${humanReadableBoard(a.board)}\n');
  });
  test('Chess♯ - test that you cannot under-promote', () {
    Position a = ChessSharp.initial;
    a = a.playSan('K@e1');
    a = a.playSan('K@e8');
    a = a.playSan('a3');
    a = a.playSan('b6');
    a = a.playSan('a4');
    a = a.playSan('b5');
    a = a.playSan('axb5');
    a = a.playSan('h6');
    a = a.playSan('b6');
    a = a.playSan('h5');
    a = a.playSan('b7');
    a = a.playSan('h4');
    expect(() => a.playSan('b8=N'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('b8=B'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('b8=R'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('b8=P'), throwsA(const TypeMatcher<PlayError>()));
    expect(() => a.playSan('b8=K'), throwsA(const TypeMatcher<PlayError>()));
    a = a.playSan('b8=Q');
    conditionalPrint('${humanReadableBoard(a.board)}\n');
  });
  test(
      "Chess♯ stalemates - test and scoring\n\t(since it's legal to move into check, we made an alternate test to determine stalemate...\n\tthe score for stalemating your opponent is 8–2 or 2–8)",
      () {
    // stalemate: king can't move
    Position a =
        ChessSharp.fromSetup(Setup.parseFen('1r5k/8/8/8/8/8/7r/K7 w - - 0 1'));
    printBoard(a);
    expect(a.outcome?.endType, EndType.stalemate);
    expect(a.outcome?.winner, Side.black);
    expect(Outcome.toPgnStringChessSharp(a.outcome), '2–8');

    // no stalemate: there's a piece in my pocket, and somewhere to place it
    a = ChessSharp.fromSetup(
        Setup.parseFen('1r5k/8/8/8/8/8/7r/K7[Q] w - - 0 1'));
    printBoard(a);
    expect(a.outcome, null);

    // stalemate: there's a piece in my pocket, but nowhere to place it
    a = ChessSharp.fromSetup(
        Setup.parseFen('4k3/8/8/8/8/8/7q/qqqnKnqq[NNBBRRQ] w - - 0 1'));
    printBoard(a);
    expect(Outcome.toPgnStringChessSharp(a.outcome), '2–8');

    // no stalemate: a pawn can promote
    a = ChessSharp.fromSetup(
        Setup.parseFen('1r5k/3P4/8/8/8/8/7r/K7 w - - 0 1'));
    printBoard(a);
    expect(a.outcome, null);

    // stalemate: the pawn is pinned
    a = ChessSharp.fromSetup(Setup.parseFen('6rk/KP5r/7q/8/8/8/8/8 w - - 0 1'));
    printBoard(a);
    expect(a.outcome?.endType, EndType.stalemate);
    expect(a.outcome?.winner, Side.black);
    expect(Outcome.toPgnStringChessSharp(a.outcome), '2–8');

    // no stalemate: I'm in check (and can get out of it)
    a = ChessSharp.fromSetup(
        Setup.parseFen('K5rk/1P5r/1q6/8/8/8/8/8 w - - 0 1'));
    printBoard(a);
    expect(a.outcome, null);

    // no stalemate: I'm in check (and can't get out of it)
    a = ChessSharp.fromSetup(Setup.parseFen('K5rk/7r/8/8/8/8/8/8 w - - 0 1'));
    printBoard(a);
    expect(a.outcome, null);
  });
  test(
      'Chess♯ impasses - test and scoring\n\t(games that go 50 moves without a capture or pawn-move\n\tthe score for an impasse is 7–3 or 3–7 if one side has more material\n\tor 4–6 if both sides have the same material)',
      () {
    // fen with 100 half-moves made
    Position a = ChessSharp.fromSetup(
        Setup.parseFen('4nnbk/8/8/8/8/8/8/KBNN4 w - - 100 100'));
    printBoard(a);
    expect(a.outcome?.endType, EndType.impasse);
    expect(a.outcome?.winner, Side.black);
    expect(Outcome.toPgnStringChessSharp(a.outcome), '4–6');

    // fen with 99 half-moves made (move last one manually)
    // trigger the impasse while walking into check
    a = ChessSharp.fromSetup(
        Setup.parseFen('4nnbk/8/8/8/8/8/8/KBNN4 w - - 99 100'));
    printBoard(a);
    expect(a.outcome, null);
    a = a.playSan('Ka2');
    expect(a.outcome?.endType, EndType.impasse);
    expect(a.outcome?.winner, Side.black);
    expect(Outcome.toPgnStringChessSharp(a.outcome), '4–6');

    // fen with 100 half-moves made, black more material
    a = ChessSharp.fromSetup(
        Setup.parseFen('4nnbk/8/8/8/8/8/8/KBN5 w - - 100 100'));
    printBoard(a);
    expect(a.outcome?.endType, EndType.impasseMoreMaterial);
    expect(a.outcome?.winner, Side.black);
    expect(Outcome.toPgnStringChessSharp(a.outcome), '3–7');

    // fen with 100 half-moves made, white more material
    a = ChessSharp.fromSetup(
        Setup.parseFen('5nbk/8/8/8/8/8/8/KBNN4 w - - 100 100'));
    printBoard(a);
    expect(a.outcome?.endType, EndType.impasseMoreMaterial);
    expect(a.outcome?.winner, Side.white);
    expect(Outcome.toPgnStringChessSharp(a.outcome), '7–3');

    // fen with 100 half-moves made, white more material, but black has a queen in the pocket
    // (pieces in the pocket don't count for material points)
    a = ChessSharp.fromSetup(
        Setup.parseFen('5nbk/8/8/8/8/8/8/KBNN4[q] w - - 100 100'));
    printBoard(a);
    expect(a.outcome?.endType, EndType.impasseMoreMaterial);
    expect(a.outcome?.winner, Side.white);
    expect(Outcome.toPgnStringChessSharp(a.outcome), '7–3');
  });
  test('Chess♯ - test pgn & fen import/export', () {
    void testPGN(String pgnFile, String finalFen) {
      conditionalPrint('\n\n${pgnFile.replaceAll('./data/', '')}\n');
      // See if the PGN we generate is the same PGN as the original
      final String pgn =
          File(pgnFile).readAsStringSync().replaceAll('\r\n', '\n');
      final game = PgnGame.parsePgn(pgn);
      expect(game.makePgn(), pgn);

      // Play the moves to see if any are illegal
      int queenDropCount = 0;
      Position position = PgnGame.startingPosition(game.headers);
      for (final node in game.moves.mainline()) {
        final move = position.parseSan(node.san);
        if (move == null) break; // Illegal move
        position = position.play(move);
        if (node.san.toUpperCase().contains('Q@')) {
          queenDropCount++;
          if (queenDropCount == 2) {
            // Print board position and FEN after the 2nd queen has been dropped (so we can copy/paste it into Stockfish)
            printBoard(position);
            conditionalPrint('Analyzable: ${position.fen}\n');
          }
        }
      }

      // Test final fen
      expect(position.fen, finalFen);

      printBoard(position);
      conditionalPrint('Final: ${position.fen}\n${game.headers['Result']}');
    }

    testPGN(
        './data/chess-sharp-david-john.pgn', '8/8/p7/8/8/8/2k5/8 w - - 0 71');

    testPGN('./data/chess-sharp-caleb-david.pgn',
        'kbb3r1/ppp4r/4pp2/8/P1N1PB2/1BP1R1pq/1P3P1P/3Q3K w - - 0 31');

    testPGN('./data/chess-sharp-jim-david.pgn',
        '8/3k4/bp2p3/4p3/PBRrP3/1P6/7P/5K2 w - - 6 53');

    testPGN('./data/chess-sharp-jim-david2.pgn',
        '3r3k/6p1/p1q3bp/8/5p2/2P2P2/PP1KQ3/7R w - - 1 42');
  });
}
