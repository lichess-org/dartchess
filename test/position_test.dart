import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';

void main() {
  group('Castles', () {
    test('Castles.fromSetup', () {
      final castles = Castles.fromSetup(Setup.standard);
      expect(castles.unmovedRooks, SquareSet.corners);
      expect(castles, Castles.standard);

      expect(castles.rookOf(Color.white, CastlingSide.queen), 0);
      expect(castles.rookOf(Color.white, CastlingSide.king), 7);
      expect(castles.rookOf(Color.black, CastlingSide.queen), 56);
      expect(castles.rookOf(Color.black, CastlingSide.king), 63);

      expect(castles.pathOf(Color.white, CastlingSide.queen).squares.toList(),
          [1, 2, 3]);
      expect(castles.pathOf(Color.white, CastlingSide.king).squares.toList(),
          [5, 6]);
      expect(castles.pathOf(Color.black, CastlingSide.queen).squares.toList(),
          [57, 58, 59]);
      expect(castles.pathOf(Color.black, CastlingSide.king).squares.toList(),
          [61, 62]);
    });

    test('discard rook', () {
      expect(Castles.standard.discardRookAt(24), Castles.standard);
      expect(
          Castles.standard.discardRookAt(7).rook[Color.white], Tuple2(0, null));
    });
  });

  group('Position validation', () {
    test('Empty board', () {
      expect(
          () => Chess.fromSetup(Setup.parseFen(kEmptyFEN)),
          throwsA(predicate((e) =>
              e is PositionError && e.cause == IllegalSetup.empty)));
    });

    test('Missing king', () {
      expect(
          () => Chess.fromSetup(Setup.parseFen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQ1BNR w HAkq - 0 1')),
          throwsA(predicate((e) =>
              e is PositionError && e.cause == IllegalSetup.kings)));
    });

    test('Opposite check', () {
      expect(
          () => Chess.fromSetup(Setup.parseFen('rnbqkbnr/pppp1ppp/8/8/8/8/PPPPQPPP/RNB1KBNR w KQkq - 0 1')),
          throwsA(predicate((e) =>
              e is PositionError && e.cause == IllegalSetup.oppositeCheck)));
    });

    test('Backrank pawns', () {
      expect(
          () => Chess.fromSetup(Setup.parseFen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPNP/RNBQKBPR w KQkq - 0 1')),
          throwsA(predicate((e) =>
              e is PositionError && e.cause == IllegalSetup.pawnsOnBackrank)));
    });

    test('checkers alignment', () {
      // Multiple checkers aligned with king.
      expect(
          () => Chess.fromSetup(
              Setup.parseFen('3R4/8/q4k2/2B5/1NK5/3b4/8/8 w - - 0 1')),
          throwsA(predicate((e) =>
              e is PositionError && e.cause == IllegalSetup.impossibleCheck)));

      // Checkers aligned with opponent king are fine.
      Chess.fromSetup(
          Setup.parseFen('8/8/5k2/p1q5/PP1rp1P1/3P1N2/2RK1r2/5nN1 w - - 0 3'));

      // En passant square aligned with checker and king.
      expect(
          () => Chess.fromSetup(
              Setup.parseFen('8/8/8/1k6/3Pp3/8/8/4KQ2 b - d3 0 1')),
          throwsA(predicate((e) =>
              e is PositionError && e.cause == IllegalSetup.impossibleCheck)));
    });
  });
}
