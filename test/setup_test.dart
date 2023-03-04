import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';

void main() {
  test('implements hashCode/==', () {
    expect(Setup.standard, Setup.standard);
    expect(Setup.parseFen(kInitialFEN), Setup.standard);
    expect(
        Setup.parseFen(
            'rnbqkbnr/pppppppp/8/8/8/P7/1PPPPPPP/RNBQKBRN w KQkq - 0 1'),
        isNot(Setup.standard));
  });

  test('parse castling fen, standard initial board', () {
    expect(
        Setup.parseFen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq')
            .unmovedRooks,
        SquareSet.corners);
    expect(
        Setup.parseFen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w -')
            .unmovedRooks,
        SquareSet.empty);
  });

  test('parse castling fen, shredder notation', () {
    expect(
        Setup.parseFen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w HAha')
            .unmovedRooks,
        SquareSet.corners);
  });

  test('invalid castling fen', () {
    expect(
        () =>
            Setup.parseFen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w BGL')
                .unmovedRooks,
        throwsA(
            predicate((e) => e is FenError && e.message == 'ERR_CASTLING')));
  });

  test('parse en passant square', () {
    expect(Setup.parseFen(kInitialFEN).epSquare, null);
    expect(
        Setup.parseFen(
                'r1bqkbnr/ppppp1pp/2n5/4Pp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6')
            .epSquare,
        45);
  });

  test('parse initial fen', () {
    final setup = Setup.parseFen(kInitialFEN);
    expect(setup, Setup.standard);
    expect(setup.board, Board.standard);
    expect(setup.turn, Side.white);
    expect(setup.unmovedRooks, SquareSet.corners);
    expect(setup.epSquare, null);
    expect(setup.halfmoves, 0);
    expect(setup.fullmoves, 1);
  });

  test('parse partial fen', () {
    final setup = Setup.parseFen(kInitialBoardFEN);
    expect(setup.board, Board.standard);
    expect(setup.turn, Side.white);
    expect(setup.unmovedRooks, SquareSet.empty);
    expect(setup.epSquare, null);
    expect(setup.halfmoves, 0);
    expect(setup.fullmoves, 1);
  });

  test('parse invalid fen', () {
    expect(
        () => Setup.parseFen(
            'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR u KQkq - 0 1'),
        throwsException);
    expect(
        () => Setup.parseFen(
            'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQQKBNR w cq - 0P1'),
        throwsException);
    expect(
        () => Setup.parseFen(
            'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w  - 0 1'),
        throwsException);
    expect(() => Setup.parseFen('4k2r/8/8/8/8/8/8/RR2K2R w KBQk - 0 1'),
        throwsException);
  });

  test('parse and make fen', () {
    for (final fen in [
      '8/8/8/8/8/8/8/8 w - - 1+2 12 42',
      '8/8/8/8/8/8/8/8[Q] b - - 0 1',
      'r3k2r/8/8/8/8/8/8/R3K2R[] w Qkq - 0 1',
      'r3kb1r/p1pN1ppp/2p1p3/8/2Pn4/3Q4/PP3PPP/R1B2q~K1[] w kq - 0 1',
      'rQ~q1kb1r/pp2pppp/2p5/8/3P1Bb1/4PN2/PPP3PP/R2QKB1R[NNpn] b KQkq - 0 9',
      'rnb1kbnr/ppp1pppp/2Pp2PP/1P3PPP/PPP1PPPP/PPP1PPPP/PPP1PPP1/PPPqPP2 w kq - 0 1',
      '5b1r/1p5p/4ppp1/4Bn2/1PPP1PP1/4P2P/3k4/4K2R w K - 1 1',
      'rnbqkb1r/p1p1nppp/2Pp4/3P1PP1/PPPPPP1P/PPP1PPPP/PPPnbqkb/PPPPPPPP w ha - 1 6',
    ]) {
      final setup = Setup.parseFen(fen);
      expect(setup.fen, fen);
    }
  });

  group('Pockets', () {
    test('increment', () {
      final pockets = Pockets.empty.increment(Side.white, Role.knight);
      expect(pockets.hasPawn(Side.white), false);
      expect(pockets.hasQuality(Side.white), true);
      expect(pockets.of(Side.white, Role.knight), 1);
      expect(pockets.size, 1);
      expect(
          pockets
              .increment(Side.white, Role.knight)
              .of(Side.white, Role.knight),
          2);
    });

    test('decrement', () {
      final pockets = Pockets.empty.increment(Side.white, Role.knight);
      expect(
          pockets
              .decrement(Side.white, Role.knight)
              .of(Side.white, Role.knight),
          0);
    });
  });
}
