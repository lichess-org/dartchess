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

      expect(castles.pathOf(Color.white, CastlingSide.queen).squares,
          equals([1, 2, 3]));
      expect(castles.pathOf(Color.white, CastlingSide.king).squares,
          equals([5, 6]));
      expect(castles.pathOf(Color.black, CastlingSide.queen).squares,
          equals([57, 58, 59]));
      expect(castles.pathOf(Color.black, CastlingSide.king).squares,
          equals([61, 62]));
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
          throwsA(predicate(
              (e) => e is PositionError && e.cause == IllegalSetup.empty)));
    });

    test('Missing king', () {
      expect(
          () => Chess.fromSetup(Setup.parseFen(
              'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQ1BNR w HAkq - 0 1')),
          throwsA(predicate(
              (e) => e is PositionError && e.cause == IllegalSetup.kings)));
    });

    test('Opposite check', () {
      expect(
          () => Chess.fromSetup(Setup.parseFen(
              'rnbqkbnr/pppp1ppp/8/8/8/8/PPPPQPPP/RNB1KBNR w KQkq - 0 1')),
          throwsA(predicate((e) =>
              e is PositionError && e.cause == IllegalSetup.oppositeCheck)));
    });

    test('Backrank pawns', () {
      expect(
          () => Chess.fromSetup(Setup.parseFen(
              'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPNP/RNBQKBPR w KQkq - 0 1')),
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

  group('Position methods', () {
    test('hasInsufficientMaterial', () {
      const insufficientMaterial = [
        ['8/5k2/8/8/8/8/3K4/8 w - - 0 1', true, true],
        ['8/3k4/8/8/2N5/8/3K4/8 b - - 0 1', true, true],
        ['8/4rk2/8/8/8/8/3K4/8 w - - 0 1', true, false],
        ['8/4qk2/8/8/8/8/3K4/8 w - - 0 1', true, false],
        ['8/4bk2/8/8/8/8/3KB3/8 w - - 0 1', false, false],
        ['8/8/3Q4/2bK4/B7/8/1k6/8 w - - 1 68', false, false],
        ['8/5k2/8/8/8/4B3/3K1B2/8 w - - 0 1', true, true],
        ['5K2/8/8/1B6/8/k7/6b1/8 w - - 0 39', true, true],
        ['8/8/8/4k3/5b2/3K4/8/2B5 w - - 0 33', true, true],
        ['3b4/8/8/6b1/8/8/R7/K1k5 w - - 0 1', false, true],
      ];

      for (final test in insufficientMaterial) {
        final pos = Chess.fromSetup(Setup.parseFen(test[0] as String));
        expect(pos.hasInsufficientMaterial(Color.white), test[1]);
        expect(pos.hasInsufficientMaterial(Color.black), test[2]);
      }
    });

    test('isInsufficientMaterial', () {
      expect(
          Chess.fromSetup(Setup.parseFen('5K2/8/8/1B6/8/k7/6b1/8 w - - 0 39'))
              .isInsufficientMaterial,
          true);

      expect(
          Chess.fromSetup(Setup.parseFen('3b4/8/8/6b1/8/8/R7/K1k5 w - - 0 1'))
              .isInsufficientMaterial,
          false);
    });
  });
}
