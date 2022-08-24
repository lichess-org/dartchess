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

    test('discard color', () {
      expect(
          Castles.standard.discardColor(Color.white).rook,
          equals(
              {Color.white: Tuple2(null, null), Color.black: Tuple2(56, 63)}));

      expect(Castles.standard.discardColor(Color.black).rook,
          equals({Color.white: Tuple2(0, 7), Color.black: Tuple2(null, null)}));
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

  group('Chess rules getters', () {
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

    test('Standard position legal moves', () {
      final moves = {
        0: SquareSet.empty,
        1: SquareSet.fromSquare(16).withSquare(18),
        2: SquareSet.empty,
        3: SquareSet.empty,
        4: SquareSet.empty,
        5: SquareSet.empty,
        6: SquareSet.fromSquare(21).withSquare(23),
        7: SquareSet.empty,
        8: SquareSet.fromSquare(16).withSquare(24),
        9: SquareSet.fromSquare(17).withSquare(25),
        10: SquareSet.fromSquare(18).withSquare(26),
        11: SquareSet.fromSquare(19).withSquare(27),
        12: SquareSet.fromSquare(20).withSquare(28),
        13: SquareSet.fromSquare(21).withSquare(29),
        14: SquareSet.fromSquare(22).withSquare(30),
        15: SquareSet.fromSquare(23).withSquare(31),
      };
      expect(Chess.standard.legalMoves, equals(moves));
    });

    test('Most known legal moves', () {
      expect(
          Chess.fromSetup(Setup.parseFen(
                  'R6R/3Q4/1Q4Q1/4Q3/2Q4Q/Q4Q2/pp1Q4/kBNN1KB1 w - - 0 1'))
              .legalMoves
              .values
              .fold<int>(0, (value, el) => value + el.size),
          218);
    });

    test('isCheck', () {
      expect(
          Chess.fromSetup(Setup.parseFen(
                  'rnbqkbnr/pppp2pp/8/4pp1Q/4P3/2N5/PPPP1PPP/R1B1KBNR b KQkq - 0 1'))
              .isCheck,
          true);
    });

    test('isGameOver', () {
      const fenTests = [
        ['rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', false],
        ['r2q2k1/5pQp/p2p4/2pP4/1p6/1P6/PBPb1PPP/4R1K1 b - - 0 20', true],
        ['8/8/8/8/8/1pk5/p7/K7 w - - 0 70', true],
        ['8/8/8/8/6k1/2N5/2K5/8 w - - 0 1', true],
      ];
      for (final test in fenTests) {
        final pos = Chess.fromSetup(Setup.parseFen(test[0] as String));
        expect(pos.isGameOver, test[1]);
      }
    });

    test('isCheckmate', () {
      expect(Chess.standard.isGameOver, false);
      expect(
          Chess.fromSetup(Setup.parseFen(
                  'r2q2k1/5pQp/p2p4/2pP4/1p6/1P6/PBPb1PPP/4R1K1 b - - 0 20'))
              .isGameOver,
          true);
    });

    test('isStalemate', () {
      expect(Chess.standard.isGameOver, false);
      expect(
          Chess.fromSetup(Setup.parseFen('8/8/8/8/8/1pk5/p7/K7 w - - 0 70'))
              .isStalemate,
          true);
    });

    test('outcome', () {
      const fenTests = [
        ['rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', null],
        [
          'r3r2k/6Q1/1qp1Nn2/p1b5/Pp3P2/8/1P4PP/R6K b - - 2 29',
          Outcome.whiteWins
        ],
        ['8/8/8/8/8/1pk5/p7/K7 w - - 0 70', Outcome.draw],
        ['8/8/8/8/6k1/2N5/2K5/8 w - - 0 1', Outcome.draw],
      ];
      for (final test in fenTests) {
        final pos = Chess.fromSetup(Setup.parseFen(test[0] as String));
        expect(pos.outcome, test[1]);
      }
    });
  });

  group('Play a move', () {
    test('e2 e4 on standard position', () {
      final pos = Chess.standard.play(Move(from: 12, to: 28));
      expect(pos.board.pieceAt(28), Piece.whitePawn);
      expect(pos.board.pieceAt(12), null);
      expect(pos.turn, Color.black);
    });

    test('play the scholar mate', () {
      final pos = Chess.standard
          .play(Move(from: 12, to: 28))
          .play(Move(from: 52, to: 36))
          .play(Move(from: 5, to: 26))
          .play(Move(from: 57, to: 42))
          .play(Move(from: 3, to: 21))
          .play(Move(from: 51, to: 43))
          .play(Move(from: 21, to: 53));

      expect(pos.isCheckmate, true);
      expect(pos.turn, Color.black);
      expect(pos.halfmoves, 0);
      expect(pos.fullmoves, 4);
      expect(pos.fen,
          'r1bqkbnr/ppp2Qpp/2np4/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4');
    });

    test('halfmoves increment', () {
      // pawn move
      expect(Chess.standard.play(Move(from: 12, to: 28)).halfmoves, 0);

      // piece move
      final pos = Chess.fromSetup(Setup.parseFen(
              'r2qr2k/5Qpp/2R1nn2/3p4/3P4/1B3P2/PB4PP/4R1K1 b - - 0 29'))
          .play(Move(from: 44, to: 38));
      expect(pos.halfmoves, 1);

      // capture move
      final pos2 = Chess.fromSetup(Setup.parseFen(
              'r2qr2k/5Qpp/2R2n2/3p2n1/3P4/1B3P2/PB4PP/4R1K1 w - - 1 30'))
          .play(Move(from: 17, to: 35));
      expect(pos2.halfmoves, 0);
    });

    test('fullmoves increment', () {
      final pos = Chess.standard.play(Move(from: 12, to: 28));
      expect(pos.fullmoves, 1);
      expect(pos.play(Move(from: 53, to: 36)).fullmoves, 2);
    });

    test('epSquare is correctly set after a double push move', () {
      final pos = Chess.standard.play(Move(from: 12, to: 28));
      expect(pos.epSquare, 20);
    });

    test('en passant capture', () {
      final pos = Chess.fromSetup(Setup.parseFen(
              'r1bqkbnr/ppppp1pp/2n5/4Pp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3'))
          .play(Move(from: 36, to: 45));
      expect(pos.board.pieceAt(45), Piece.whitePawn);
      expect(pos.board.pieceAt(37), null);
      expect(pos.epSquare, null);
    });

    test('castling move', () {
      final pos = Chess.fromSetup(Setup.parseFen(
              'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4'))
          .play(Move(from: 4, to: 6));
      expect(pos.board.pieceAt(6), Piece.whiteKing);
      expect(pos.board.pieceAt(5), Piece.whiteRook);
      expect(
          pos.castles.unmovedRooks.isIntersected(SquareSet.fromRank(0)), false);
      expect(pos.castles.rook[Color.white], equals(Tuple2(null, null)));
    });

    test('rook move removes castling right', () {
      final pos = Chess.fromSetup(Setup.parseFen(
              'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4'))
          .play(Move(from: 7, to: 5));
      expect(pos.castles.rook[Color.white], equals(Tuple2(0, null)));
      expect(pos.castles.unmovedRooks.has(7), false);
    });

    test('capturing a rook removes castling right', () {
      final pos = Chess.fromSetup(Setup.parseFen(
              'r1bqk1nr/pppp1pbp/2n1p1p1/8/2B1P3/1P3N2/P1PP1PPP/RNBQK2R b KQkq - 4 4'))
          .play(Move(from: 54, to: 0));
      expect(pos.castles.rook[Color.white], equals(Tuple2(null, 7)));
      expect(pos.castles.unmovedRooks.has(0), false);
    });
  });
}
