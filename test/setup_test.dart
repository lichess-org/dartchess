import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';

void main() {
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
    expect(setup.turn, Color.white);
    expect(setup.unmovedRooks, SquareSet.corners);
    expect(setup.epSquare, null);
    expect(setup.halfmoves, 0);
    expect(setup.fullmoves, 1);
  });

  test('parse partial fen', () {
    final setup = Setup.parseFen(kInitialBoardFEN);
    expect(setup.board, Board.standard);
    expect(setup.turn, Color.white);
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
      'rnb1kbnr/ppp1pppp/2Pp2PP/1P3PPP/PPP1PPPP/PPP1PPPP/PPP1PPP1/PPPqPP2 w kq - 0 1',
      '5b1r/1p5p/4ppp1/4Bn2/1PPP1PP1/4P2P/3k4/4K2R w K - 1 1',
      'rnbqkb1r/p1p1nppp/2Pp4/3P1PP1/PPPPPP1P/PPP1PPPP/PPPnbqkb/PPPPPPPP w ha - 1 6',
    ]) {
      final setup = Setup.parseFen(fen);
      expect(setup.fen, fen);
    }
  });
}
