import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';

void main() {
  group('Position', () {
    test('implements hashCode/==', () {
      expect(Chess.initial, Chess.initial);
      expect(Chess.initial, isNot(Antichess.initial));
      expect(Chess.initial, isNot(Chess.initial.play(Move.fromUci('e2e4')!)));
    });

    test('Chess.toString()', () {
      expect(Chess.initial.toString(),
          'Chess(board: rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR, turn: Side.white, castles: Castles(unmovedRooks: SquareSet(0x8100000000000081)), halfmoves: 0, fullmoves: 1)');
    });

    test('Antichess.toString()', () {
      expect(Antichess.initial.toString(),
          'Antichess(board: $kInitialBoardFEN, turn: Side.white, castles: Castles(unmovedRooks: SquareSet(0)), halfmoves: 0, fullmoves: 1)');
    });
  });

  group('Castles', () {
    test('implements hashCode/==', () {
      expect(Castles.standard, Castles.standard);
      expect(Castles.standard, isNot(Castles.empty));
      expect(
          Castles.standard,
          isNot(Castles.fromSetup(Setup.parseFen(
              'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQq - 0 1'))));
      expect(
          Castles.standard,
          isNot(Castles.fromSetup(Setup.parseFen(
              'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBRN w KQkq - 0 1'))));
    });
    test('fromSetup', () {
      final castles = Castles.fromSetup(Setup.standard);
      expect(castles.unmovedRooks, SquareSet.corners);
      expect(castles, Castles.standard);

      expect(castles.rookOf(Side.white, CastlingSide.queen), 0);
      expect(castles.rookOf(Side.white, CastlingSide.king), 7);
      expect(castles.rookOf(Side.black, CastlingSide.queen), 56);
      expect(castles.rookOf(Side.black, CastlingSide.king), 63);

      expect(castles.pathOf(Side.white, CastlingSide.queen).squares,
          equals([1, 2, 3]));
      expect(castles.pathOf(Side.white, CastlingSide.king).squares,
          equals([5, 6]));
      expect(castles.pathOf(Side.black, CastlingSide.queen).squares,
          equals([57, 58, 59]));
      expect(castles.pathOf(Side.black, CastlingSide.king).squares,
          equals([61, 62]));
    });

    test('discard rook', () {
      expect(Castles.standard.discardRookAt(24), Castles.standard);
      expect(
          Castles.standard.discardRookAt(7).rooksPositions[Side.white],
          IMap(
              const {CastlingSide.queen: Squares.a1, CastlingSide.king: null}));
    });

    test('discard side', () {
      expect(
          Castles.standard.discardSide(Side.white).rooksPositions,
          equals(BySide({
            Side.white: ByCastlingSide(
              const {CastlingSide.queen: null, CastlingSide.king: null},
            ),
            Side.black: ByCastlingSide(
              const {CastlingSide.queen: 56, CastlingSide.king: 63},
            )
          })));

      expect(
          Castles.standard.discardSide(Side.black).rooksPositions,
          equals(BySide({
            Side.white: ByCastlingSide(
                const {CastlingSide.queen: 0, CastlingSide.king: 7}),
            Side.black: ByCastlingSide(
                const {CastlingSide.queen: null, CastlingSide.king: null})
          })));
    });
  });

  group('san', () {
    test('makeSan en passant', () {
      final setup = Setup.parseFen('6bk/7b/8/3pP3/8/8/8/Q3K3 w - d6 0 2');
      final pos = Chess.fromSetup(setup);
      final move = Move.fromUci('e5d6')!;
      final (newPos, san) = pos.makeSan(move);
      expect(san, 'exd6#');
      expect(newPos.fen, '6bk/7b/3P4/8/8/8/8/Q3K3 b - - 0 2');
    });

    test('makeSan with scholar mate', () {
      const moves = [
        NormalMove(from: 12, to: 28),
        NormalMove(from: 52, to: 36),
        NormalMove(from: 5, to: 26),
        NormalMove(from: 57, to: 42),
        NormalMove(from: 3, to: 21),
        NormalMove(from: 51, to: 43),
        NormalMove(from: 21, to: 53),
      ];
      final (_, sans) = moves
          .fold<(Position<Chess>, List<String>)>((Chess.initial, []), (acc, e) {
        final (pos, sans) = acc;
        final (newPos, san) = pos.makeSan(e);
        return (newPos, [...sans, san]);
      });
      expect(sans, equals(['e4', 'e5', 'Bc4', 'Nc6', 'Qf3', 'd6', 'Qxf7#']));
    });

    test('parse basic san', () {
      const position = Chess.initial;
      expect(
          position.parseSan('e4'), equals(const NormalMove(from: 12, to: 28)));
      expect(
          position.parseSan('Nf3'), equals(const NormalMove(from: 6, to: 21)));
      expect(position.parseSan('Nf6'), null);
      expect(position.parseSan('Ke2'), null);
      expect(position.parseSan('O-O'), null);
      expect(position.parseSan('O-O-O'), null);
    });

    test('parse pawn capture', () {
      Position pos = Chess.initial;
      const line = ['e4', 'd5', 'c4', 'Nf6', 'exd5'];
      for (final san in line) {
        pos = pos.play(pos.parseSan(san)!);
      }
      expect(pos.fen,
          'rnbqkb1r/ppp1pppp/5n2/3P4/2P5/8/PP1P1PPP/RNBQKBNR b KQkq - 0 3');

      final pos2 = Chess.fromSetup(
          Setup.parseFen('r4br1/pp1Npkp1/2P4p/5P2/6P1/5KnP/PP6/R1B5 b - -'));
      expect(pos2.parseSan('bxc6'), equals(const NormalMove(from: 49, to: 42)));

      final pos3 = Chess.fromSetup(Setup.parseFen(
          '2rq1rk1/pb2bppp/1p2p3/n1ppPn2/2PP4/PP3N2/1B1NQPPP/RB3RK1 b - -'));
      expect(pos3.parseSan('c4'), isNull);
    });

    test('parse fools mate', () {
      const moves = ['e4', 'e5', 'Qh5', 'Nf6', 'Bc4', 'Nc6', 'Qxf7#'];
      Position position = Chess.initial;
      for (final move in moves) {
        position = position.play(position.parseSan(move)!);
      }
      expect(position.isCheckmate, equals(true));
    });

    test('cannot parse drop moves in Chess', () {
      const illegalMoves = ['Q@e3', 'N@d4'];
      const position = Chess.initial;
      for (final move in illegalMoves) {
        expect(position.parseSan(move), equals(null));
      }
    });

    test('opening pawn moves', () {
      const legalSans = [
        'a3',
        'a4',
        'b3',
        'b4',
        'c3',
        'c4',
        'd3',
        'd4',
        'e3',
        'e4',
        'f3',
        'f4',
        'g3',
        'g4',
        'h3',
        'h4',
      ];

      const illegalSans = [
        'a1',
        'a5',
        'axd6',
        'b1',
        'b5',
        'bxd9',
        'c1',
        'c5',
        'c8',
        'd1',
        'd5',
        'c0',
        'e1',
        'e5',
        'e6',
        'f1',
        'f5',
        'fxd3',
        'g1',
        'g5',
        'fxh7',
        'h1',
        'h5',
        'h?1',
      ];
      const position = Chess.initial;
      for (final san in legalSans) {
        expect(position.parseSan(san) != null, true);
      }

      for (final san in illegalSans) {
        expect(position.parseSan(san) == null, true);
      }
    });

    test('opening knight moves', () {
      const legalSans = [
        'Na3',
        'Nc3',
        'Nf3',
        'Nh3',
      ];

      const illegalSans = [
        'Ba3',
        'Bc3',
        'Bf3',
        'Bh3',
        'Ne4',
        'Nb1',
        'Ng1',
      ];

      const position = Chess.initial;
      for (final san in legalSans) {
        expect(position.parseSan(san) != null, true);
      }

      for (final san in illegalSans) {
        expect(position.parseSan(san) == null, true);
      }
    });

    test('overspecified pawn move', () {
      const position = Chess.initial;
      expect(
          position.parseSan('2e4'), equals(const NormalMove(from: 12, to: 28)));
    });

    test('chess960 parseSan castle moves', () {
      Position<Chess> position = Chess.fromSetup(Setup.parseFen(
          'brknnqrb/pppppppp/8/8/8/8/PPPPPPPP/BRKNNQRB w KQkq - 0 1'));
      const moves =
          'b3 b6 Ne3 g6 Bxh8 Rxh8 O-O-O Qg7 Kb1 Ne6 Nd3 Nf6 h3 O-O-O Nc4 d5 Na3 Nd4 e3 Nc6 Nb5 Rhe8 f3 e5 g4 Re6 g5 Nd7 h4 h5 Bg2 a6 Nc3 Nc5 Nxc5 bxc5 Qxa6+ Bb7 Qa3 Kd7 Qxc5 Ra8 Nxd5 Rd6 Nf6+ Kc8 Ne8 Qf8 Nxd6+ cxd6 Qc3 f5 f4 e4 d3 Qd8 dxe4 Qb6 exf5 gxf5 Rxd6';
      for (final move in moves.split(' ')) {
        position = position.playUnchecked(position.parseSan(move)!);
      }
      expect(position.fullmoves, equals(31));
      expect(position.fen,
          'r1k5/1b6/1qnR4/5pPp/5P1P/1PQ1P3/P1P3B1/1K4R1 b - - 0 31');
    });
  });

  group('Chess', () {
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
                e is PositionError &&
                e.cause == IllegalSetup.pawnsOnBackrank)));
      });

      test('checkers alignment', () {
        // Multiple checkers aligned with king.
        expect(
            () => Chess.fromSetup(
                Setup.parseFen('3R4/8/q4k2/2B5/1NK5/3b4/8/8 w - - 0 1')),
            throwsA(predicate((e) =>
                e is PositionError &&
                e.cause == IllegalSetup.impossibleCheck)));

        // Checkers aligned with opponent king are fine.
        Chess.fromSetup(Setup.parseFen(
            '8/8/5k2/p1q5/PP1rp1P1/3P1N2/2RK1r2/5nN1 w - - 0 3'));

        // En passant square aligned with checker and king.
        expect(
            () => Chess.fromSetup(
                Setup.parseFen('8/8/8/1k6/3Pp3/8/8/4KQ2 b - d3 0 1')),
            throwsA(predicate((e) =>
                e is PositionError &&
                e.cause == IllegalSetup.impossibleCheck)));
      });
    });

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
        expect(pos.hasInsufficientMaterial(Side.white), test[1]);
        expect(pos.hasInsufficientMaterial(Side.black), test[2]);
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

    test('standard position legal moves', () {
      final moves = IMap({
        0: SquareSet.empty,
        1: const SquareSet.fromSquare(16).withSquare(18),
        2: SquareSet.empty,
        3: SquareSet.empty,
        4: SquareSet.empty,
        5: SquareSet.empty,
        6: const SquareSet.fromSquare(21).withSquare(23),
        7: SquareSet.empty,
        8: const SquareSet.fromSquare(16).withSquare(24),
        9: const SquareSet.fromSquare(17).withSquare(25),
        10: const SquareSet.fromSquare(18).withSquare(26),
        11: const SquareSet.fromSquare(19).withSquare(27),
        12: const SquareSet.fromSquare(20).withSquare(28),
        13: const SquareSet.fromSquare(21).withSquare(29),
        14: const SquareSet.fromSquare(22).withSquare(30),
        15: const SquareSet.fromSquare(23).withSquare(31),
      });
      expect(Chess.initial.legalMoves, equals(moves));
    });

    test('most known legal moves', () {
      expect(
          Chess.fromSetup(Setup.parseFen(
                  'R6R/3Q4/1Q4Q1/4Q3/2Q4Q/Q4Q2/pp1Q4/kBNN1KB1 w - - 0 1'))
              .legalMoves
              .values
              .fold<int>(0, (value, el) => value + el.size),
          218);
    });

    test('castling legal moves', () {
      final pos = Chess.fromSetup(Setup.parseFen(
          'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1'));
      expect(pos.legalMovesOf(4), const SquareSet(0x00000000000000A9));
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
      expect(Chess.initial.isGameOver, false);
      expect(
          Chess.fromSetup(Setup.parseFen(
                  'r2q2k1/5pQp/p2p4/2pP4/1p6/1P6/PBPb1PPP/4R1K1 b - - 0 20'))
              .isGameOver,
          true);
    });

    test('isStalemate', () {
      expect(Chess.initial.isGameOver, false);
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
        final pos = Chess.fromSetup(Setup.parseFen(test[0]! as String));
        expect(pos.outcome, test[1]);
      }
    });

    test('isLegal', () {
      expect(Chess.initial.isLegal(const NormalMove(from: 12, to: 28)), true);
      expect(Chess.initial.isLegal(const NormalMove(from: 12, to: 29)), false);
      final promPos = Chess.fromSetup(
          Setup.parseFen('8/5P2/2RK2P1/8/4k3/8/8/7r w - - 0 1'));
      expect(
          promPos.isLegal(
              const NormalMove(from: 53, to: 61, promotion: Role.king)),
          false);
      expect(
          promPos.isLegal(
              const NormalMove(from: 42, to: 58, promotion: Role.queen)),
          false);
      expect(
          promPos.isLegal(
              const NormalMove(from: 46, to: 54, promotion: Role.queen)),
          false);
      expect(
          promPos.isLegal(
              const NormalMove(from: 53, to: 61, promotion: Role.queen)),
          true);
    });

    group('play', () {
      test('a move not valid', () {
        expect(() => Chess.initial.play(const NormalMove(from: 12, to: 44)),
            throwsA(const TypeMatcher<PlayError>()));
      });

      test('e2 e4 on standard position', () {
        final pos = Chess.initial.play(const NormalMove(from: 12, to: 28));
        expect(pos.board.pieceAt(28), Piece.whitePawn);
        expect(pos.board.pieceAt(12), null);
        expect(pos.turn, Side.black);
      });

      test('scholar mate', () {
        final pos = Chess.initial
            .play(const NormalMove(from: 12, to: 28))
            .play(const NormalMove(from: 52, to: 36))
            .play(const NormalMove(from: 5, to: 26))
            .play(const NormalMove(from: 57, to: 42))
            .play(const NormalMove(from: 3, to: 21))
            .play(const NormalMove(from: 51, to: 43))
            .play(const NormalMove(from: 21, to: 53));

        expect(pos.isCheckmate, true);
        expect(pos.turn, Side.black);
        expect(pos.halfmoves, 0);
        expect(pos.fullmoves, 4);
        expect(pos.fen,
            'r1bqkbnr/ppp2Qpp/2np4/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4');
      });

      test('halfmoves increment', () {
        // pawn move
        expect(Chess.initial.play(const NormalMove(from: 12, to: 28)).halfmoves,
            0);

        // piece move
        final pos = Chess.fromSetup(Setup.parseFen(
                'r2qr2k/5Qpp/2R1nn2/3p4/3P4/1B3P2/PB4PP/4R1K1 b - - 0 29'))
            .play(const NormalMove(from: 44, to: 38));
        expect(pos.halfmoves, 1);

        // capture move
        final pos2 = Chess.fromSetup(Setup.parseFen(
                'r2qr2k/5Qpp/2R2n2/3p2n1/3P4/1B3P2/PB4PP/4R1K1 w - - 1 30'))
            .play(const NormalMove(from: 17, to: 35));
        expect(pos2.halfmoves, 0);
      });

      test('fullmoves increment', () {
        final pos = Chess.initial.play(const NormalMove(from: 12, to: 28));
        expect(pos.fullmoves, 1);
        expect(pos.play(const NormalMove(from: 52, to: 36)).fullmoves, 2);
      });

      test('epSquare is correctly set after a double push move', () {
        final pos = Chess.initial.play(const NormalMove(from: 12, to: 28));
        expect(pos.epSquare, 20);
      });

      test('en passant capture', () {
        final pos = Chess.fromSetup(Setup.parseFen(
                'r1bqkbnr/ppppp1pp/2n5/4Pp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3'))
            .play(const NormalMove(from: 36, to: 45));
        expect(pos.board.pieceAt(45), Piece.whitePawn);
        expect(pos.board.pieceAt(37), null);
        expect(pos.epSquare, null);
      });

      test('rook move removes castling right', () {
        final pos = Chess.fromSetup(Setup.parseFen(
                'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4'))
            .play(const NormalMove(from: 7, to: 5));
        expect(
            pos.castles.rooksPositions[Side.white],
            equals(IMap(const {
              CastlingSide.queen: Squares.a1,
              CastlingSide.king: null
            })));
        expect(pos.castles.unmovedRooks.has(7), false);
      });

      test('capturing a rook removes castling right', () {
        final pos = Chess.fromSetup(Setup.parseFen(
                'r1bqk1nr/pppp1pbp/2n1p1p1/8/2B1P3/1P3N2/P1PP1PPP/RNBQK2R b KQkq - 4 4'))
            .play(const NormalMove(from: 54, to: 0));
        expect(pos.castles.rookOf(Side.white, CastlingSide.queen), isNull);
        expect(pos.castles.rookOf(Side.white, CastlingSide.king), Squares.h1);
        expect(pos.castles.unmovedRooks.has(0), false);
      });

      test('king captures unmoved rook', () {
        final pos = Chess.fromSetup(
            Setup.parseFen('8/8/8/B2p3Q/2qPp1P1/b7/2P2PkP/4K2R b K - 0 1'));
        const move = NormalMove(from: 14, to: 7);
        expect(pos.isLegal(move), true);
        final pos2 = pos.play(move);
        expect(pos2.fen, '8/8/8/B2p3Q/2qPp1P1/b7/2P2P1P/4K2k w - - 0 2');
      });

      test('en passant and unrelated check', () {
        final setup = Setup.parseFen(
            'rnbqk1nr/bb3p1p/1q2r3/2pPp3/3P4/7P/1PP1NpPP/R1BQKBNR w KQkq c6');
        expect(
            () => Chess.fromSetup(setup),
            throwsA(predicate((e) =>
                e is PositionError &&
                e.cause == IllegalSetup.impossibleCheck)));
        final pos = Chess.fromSetup(setup, ignoreImpossibleCheck: true);
        const enPassant = NormalMove(from: 35, to: 42);
        expect(pos.isLegal(enPassant), false);
      });

      test('castling move', () {
        final pos = Chess.fromSetup(Setup.parseFen(
                'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4'))
            .play(const NormalMove(from: 4, to: 6));
        expect(pos.board.pieceAt(6), Piece.whiteKing);
        expect(pos.board.pieceAt(5), Piece.whiteRook);
        expect(
            pos.castles.unmovedRooks.isIntersected(const SquareSet.fromRank(0)),
            false);
        expect(pos.castles.rookOf(Side.white, CastlingSide.king), isNull);
        expect(pos.castles.rookOf(Side.white, CastlingSide.queen), isNull);
      });

      test('castling moves', () {
        final pos =
            Chess.fromSetup(Setup.parseFen('2r5/8/8/8/8/8/6PP/k2KR3 w K -'));
        const move = NormalMove(from: 3, to: 4);
        expect(pos.play(move).fen, '2r5/8/8/8/8/8/6PP/k4RK1 b - - 1 1');

        final pos2 = Chess.fromSetup(Setup.parseFen(
            'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1'));
        const move2 = NormalMove(from: 4, to: 0);
        expect(pos2.play(move2).fen,
            'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/2KR3R b kq - 1 1');

        final pos3 = Chess.fromSetup(Setup.parseFen(
            '1r2k2r/p1b1n1pp/1q3p2/1p2pPQ1/4P3/2P4P/1B2B1P1/R3K2R w KQk - 0 20'));
        const queenSide = NormalMove(from: 4, to: 0);
        const altQueenSide = NormalMove(from: 4, to: 2);
        expect(pos3.normalizeMove(queenSide), queenSide);
        expect(pos3.normalizeMove(altQueenSide), queenSide);
        expect(pos3.play(altQueenSide).fen,
            '1r2k2r/p1b1n1pp/1q3p2/1p2pPQ1/4P3/2P4P/1B2B1P1/2KR3R b k - 1 20');
      });
    });
  });

  group('Atomic', () {
    test('king exploded', () {
      final pos1 = Atomic.fromSetup(Setup.parseFen(
          'r4b1r/ppp1pppp/7n/8/8/8/PPPPPPPP/RNBQKB1R b KQ - 0 3'));
      expect(pos1.isGameOver, true);
      expect(pos1.isVariantEnd, true);
      expect(pos1.outcome, Outcome.whiteWins);

      final pos2 = Atomic.fromSetup(Setup.parseFen(
          'rn5r/pp4pp/2p3Nn/5p2/1b2P1PP/8/PPP2P2/R1B1KB1R b KQ - 0 9'));
      expect(pos2.isGameOver, true);
      expect(pos2.isVariantEnd, true);
      expect(pos2.outcome, Outcome.whiteWins);
    });

    test('insufficient material', () {
      for (final test in [
        ['8/3k4/8/8/2N5/8/3K4/8 b - -', true, true],
        ['8/4rk2/8/8/8/8/3K4/8 w - -', true, true],
        ['8/4qk2/8/8/8/8/3K4/8 w - -', true, false],
        ['8/1k6/8/2n5/8/3NK3/8/8 b - -', false, false],
        ['8/4bk2/8/8/8/8/3KB3/8 w - -', true, true],
        ['4b3/5k2/8/8/8/8/3KB3/8 w - -', false, false],
        ['3Q4/5kKB/8/8/8/8/8/8 b - -', false, true],
        ['8/5k2/8/8/8/8/5K2/4bb2 w - -', true, false],
        ['8/5k2/8/8/8/8/5K2/4nb2 w - -', true, false],
      ]) {
        final pos = Atomic.fromSetup(Setup.parseFen(test[0] as String));
        expect(pos.hasInsufficientMaterial(Side.white), test[1]);
        expect(pos.hasInsufficientMaterial(Side.black), test[2]);
      }
    });
  });

  group('Antichess', () {
    test('insufficient material', () {
      const falseNegative = false;
      for (final test in [
        ['8/4bk2/8/8/8/8/3KB3/8 w - -', false, false],
        ['4b3/5k2/8/8/8/8/3KB3/8 w - -', false, false],
        ['8/8/8/6b1/8/3B4/4B3/5B2 w - -', true, true],
        ['8/8/5b2/8/8/3B4/3B4/8 w - -', true, false],
        ['8/5p2/5P2/8/3B4/1bB5/8/8 b - -', falseNegative, falseNegative],
        ['8/8/8/1n2N3/8/8/8/8 w - - 0 32', true, false],
        ['8/3N4/8/1n6/8/8/8/8 b - - 1 32', true, false],
        ['6n1/8/8/4N3/8/8/8/8 b - - 0 27', false, true],
        ['8/8/5n2/4N3/8/8/8/8 w - - 1 28', false, true],
        ['8/3n4/8/8/8/8/8/8 w - - 0 29', false, true],
      ]) {
        final pos = Antichess.fromSetup(Setup.parseFen(test[0] as String));
        expect(pos.hasInsufficientMaterial(Side.white), test[1]);
        expect(pos.hasInsufficientMaterial(Side.black), test[2]);
      }
    });

    test('en passant', () {
      final setup = Setup.parseFen(
          'r1bqkbn1/p1ppp3/2n4p/6p1/1Pp5/4P3/P2P1PP1/R1B1K3 b - b3 0 11');
      final pos = Antichess.fromSetup(setup);
      final move = Move.fromUci('c4b3')!;
      expect(pos.isLegal(move), isTrue);

      final sanMove = pos.parseSan('cxb3');
      expect(move, equals(sanMove));
    });

    test('parse san', () {
      Position position = Antichess.initial;
      final moves = [
        'g3',
        'Nh6',
        'g4',
        'Nxg4',
        'b3',
        'Nxh2',
        'Rxh2',
        'g5',
        'Rxh7',
        'Rxh7',
        'Bh3',
        'Rxh3',
        'Nxh3',
        'Na6',
        'Nxg5',
        'Nb4',
        'Nxf7',
        'Nxc2',
        'Qxc2',
        'Kxf7',
        'Qxc7',
        'Qxc7',
        'a4',
        'Qxc1',
        'Ra3',
        'Qxa3',
        'Nxa3',
        'b5',
        'Nxb5',
        'Rb8',
        'Nxa7',
        'Rxb3',
        'Nxc8',
        'Rg3',
        'Nxe7',
        'Bxe7',
        'fxg3',
        'Bh4',
        'gxh4',
        'd5',
        'e4',
        'dxe4',
        'd3',
        'exd3',
        'Kf1',
        'd2',
        'Kg1',
        'Kf6',
        'a5',
        'Ke6',
        'a6',
        'Kd7',
        'a7',
        'Kc7',
        'h5',
        'd1=B',
        'a8=B',
        'Bxh5',
        'Bf3',
        'Bxf3',
        'Kg2',
        'Bxg2#',
      ];
      for (final move in moves) {
        position = position.play(position.parseSan(move)!);
      }
      expect(position.fen, equals('8/2k5/8/8/8/8/6b1/8 w - - 0 32'));
    });

    test('parse san, king promotion', () {
      const moves = [
        'e4',
        'c6',
        'h3',
        'd5',
        'exd5',
        'Bxh3',
        'dxc6',
        'Bxg2',
        'cxb7',
        'Bxh1',
        'bxa8=K'
      ];
      Position position = Antichess.initial;
      for (final move in moves) {
        position = position.play(position.parseSan(move)!);
      }
      expect(position.fen,
          equals('Kn1qkbnr/p3pppp/8/8/8/8/PPPP1P2/RNBQKBNb b - - 0 6'));
    });
  });

  group('Crazyhouse', () {
    test('insufficient material', () {
      for (final test in [
        ['8/5k2/8/8/8/8/3K2N1/8[] w - -', true, true],
        ['8/5k2/8/8/8/5B2/3KB3/8[] w - -', false, false],
        ['8/8/8/8/3k4/3N~4/3K4/8 w - - 0 1', false, false],
      ]) {
        final pos = Crazyhouse.fromSetup(Setup.parseFen(test[0] as String));
        expect(pos.hasInsufficientMaterial(Side.white), test[1]);
        expect(pos.hasInsufficientMaterial(Side.black), test[2]);
      }
    });

    test('parse san', () {
      Position position = Crazyhouse.initial;
      final moves = [
        'd4',
        'd5',
        'Nc3',
        'Bf5',
        'e3',
        'e6',
        'Bd3',
        'Bg6',
        'Nf3',
        'Bd6',
        'O-O',
        'Ne7',
        'g3',
        'Nbc6',
        'Re1',
        'O-O',
        'Ne2',
        'e5',
        'dxe5',
        'Nxe5',
        'Nxe5',
        'Bxe5',
        'f4',
        'N@f3+',
        'Kg2',
        'Nxe1+',
        'Qxe1',
        'Bd6',
        '@f3',
        '@e4',
        'fxe4',
        'dxe4',
        'Bc4',
        '@f3+',
        'Kf2',
        'fxe2',
        'Qxe2',
        'N@h3+',
        'Kg2',
        'R@f2+',
        'Qxf2',
        'Nxf2',
        'Kxf2',
        'Q@f3+',
        'Ke1',
        'Bxf4',
        'gxf4',
        'Qdd1#',
      ];
      for (final move in moves) {
        position = position.play(position.parseSan(move)!);
      }
      expect(
          position.fen,
          equals(
              'r4rk1/ppp1nppp/6b1/8/2B1pP2/4Pq2/PPP4P/R1BqK3[PPNNNBRp] w - - 1 25'));
    });

    test('castle checkmates', () {
      Position position = Crazyhouse.initial;
      final moves = [
        'd4',
        'f5',
        'Nc3',
        'Nf6',
        'Nf3',
        'e6',
        'Bg5',
        'Be7',
        'Bxf6',
        'Bxf6',
        'e4',
        'fxe4',
        'Nxe4',
        'b6',
        'Ne5',
        'O-O',
        'Bd3',
        'Bb7',
        'Qh5',
        'Qe7',
        'Qxh7+',
        'Kxh7',
        'Nxf6+',
        'Kh6',
        'Neg4+',
        'Kg5',
        'h4+',
        'Kf4',
        'g3+',
        'Kf3',
        'Be2+',
        'Kg2',
        'Rh2+',
        'Kg1',
        'O-O-O#',
      ];
      for (final move in moves) {
        position = position.play(position.parseSan(move)!);
      }
      expect(position.isCheckmate, equals(true));
    });
  });

  group('King of the hill', () {
    test('insufficient material', () {
      for (final test in [
        ['8/5k2/8/8/8/8/3K4/8 w - -', false, false],
      ]) {
        final pos = KingOfTheHill.fromSetup(Setup.parseFen(test[0] as String));
        expect(pos.hasInsufficientMaterial(Side.white), test[1]);
        expect(pos.hasInsufficientMaterial(Side.black), test[2]);
      }
    });
    test('game end conditions', () {
      final pos = KingOfTheHill.fromSetup(
          Setup.parseFen('8/5k2/8/8/8/8/1K6/8 w - - 0 1'));
      expect(pos.isInsufficientMaterial, false);
      expect(pos.isCheck, false);
      expect(pos.isVariantEnd, false);
      expect(pos.variantOutcome, null);
      expect(pos.outcome, null);
      expect(pos.isGameOver, false);

      final pos2 = KingOfTheHill.fromSetup(Setup.parseFen(
          'r1bqkbnr/ppp2ppp/2np4/4p3/4K3/8/PPPP1PPP/RNBQ1BNR w HAkq - 0 1'));
      expect(pos2.isVariantEnd, true);
      expect(pos2.isGameOver, true);
      expect(pos2.variantOutcome, Outcome.whiteWins);
    });
  });

  group('Racing Kings', () {
    test('start position', () {
      const position = RacingKings.initial;
      expect(position.fen, equals('8/8/8/8/8/8/krbnNBRK/qrbnNBRQ w - - 0 1'));
    });

    test('draw', () {
      // Both pieces are on the backrank
      final position = RacingKings.fromSetup(
          Setup.parseFen('kr3NK1/1q2R3/8/8/8/5n2/2N5/1rb2B1R w - - 11 14'));
      expect(position.isVariantEnd, true);
      expect(position.variantOutcome, Outcome.draw);
    });

    test('white win', () {
      final position = RacingKings.fromSetup(
          Setup.parseFen('2KR4/k7/2Q5/4q3/8/8/8/2N5 b - - 0 1'));
      expect(position.isVariantEnd, true);
      expect(position.variantOutcome, Outcome.whiteWins);
    });

    test('black win', () {
      final position = RacingKings.fromSetup(
          Setup.parseFen('1k6/6K1/8/8/8/8/8/8 w - - 0 1'));
      expect(position.isVariantEnd, true);
      expect(position.variantOutcome, Outcome.blackWins);
    });

    test('game ongoing', () {
      // While the white king is on the back rank
      // The black king can reach the back rank this turn
      final position =
          RacingKings.fromSetup(Setup.parseFen('1K6/7k/8/8/8/8/8/8 b - - 0 1'));
      expect(position.isVariantEnd, false);
      expect(position.variantOutcome, null);
    });
  });

  group('Three check', () {
    test('insufficient material', () {
      for (final test in [
        ['8/5k2/8/8/8/8/3K4/8 w - - 3+3', true, true],
        ['8/5k2/8/8/8/8/3K2N1/8 w - - 3+3', false, true],
      ]) {
        final pos = ThreeCheck.fromSetup(Setup.parseFen(test[0] as String));
        expect(pos.hasInsufficientMaterial(Side.white), test[1]);
        expect(pos.hasInsufficientMaterial(Side.black), test[2]);
      }
    });

    test('remaining checks', () {
      final pos = ThreeCheck.fromSetup(Setup.parseFen(
          'rnbqkbnr/ppp1pppp/3p4/8/8/4P3/PPPP1PPP/RNBQKBNR w KQkq - 3+3 0 2'));
      expect(pos.play(Move.fromUci('f1b5')!).fen,
          'rnbqkbnr/ppp1pppp/3p4/1B6/8/4P3/PPPP1PPP/RNBQK1NR b KQkq - 2+3 1 2');
    });
  });

  group('Horde', () {
    test('insufficient material', () {
      for (final test in [
        ['8/5k2/8/8/8/4NN2/8/8 w - - 0 1', true, false],
        ['8/8/8/2B5/p7/kp6/pq6/8 b - - 0 1', false, false],
        ['8/8/8/2B5/r7/kn6/nr6/8 b - - 0 1', true, false],
        ['8/8/1N6/rb6/kr6/qn6/8/8 b - - 0 1', false, false],
        ['8/8/1N6/qq6/kq6/nq6/8/8 b - - 0 1', true, false],
        ['8/P1P5/8/8/8/8/brqqn3/k7 b - - 0 1', false, false],
      ]) {
        final pos = Horde.fromSetup(Setup.parseFen(test[0] as String));
        expect(pos.hasInsufficientMaterial(Side.white), test[1]);
        expect(pos.hasInsufficientMaterial(Side.black), test[2]);
      }
    });
  });
}
