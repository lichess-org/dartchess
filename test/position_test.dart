import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';

void main() {
  group('Castles', () {
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
      expect(Castles.standard.discardRookAt(7).rook[Side.white],
          const Tuple2(0, null));
    });

    test('discard side', () {
      expect(
          Castles.standard.discardSide(Side.white).rook,
          equals({
            Side.white: const Tuple2(null, null),
            Side.black: const Tuple2(56, 63)
          }));

      expect(
          Castles.standard.discardSide(Side.black).rook,
          equals({
            Side.white: const Tuple2(0, 7),
            Side.black: const Tuple2(null, null)
          }));
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

    group('san', () {
      test('en passant', () {
        final setup = Setup.parseFen('6bk/7b/8/3pP3/8/8/8/Q3K3 w - d6 0 2');
        final pos = Chess.fromSetup(setup);
        final move = Move.fromUci('e5d6');
        expect(pos.toSan(move), 'exd6#');
      });

      test('playToSan with scholar mate', () {
        const moves = [
          NormalMove(from: 12, to: 28),
          NormalMove(from: 52, to: 36),
          NormalMove(from: 5, to: 26),
          NormalMove(from: 57, to: 42),
          NormalMove(from: 3, to: 21),
          NormalMove(from: 51, to: 43),
          NormalMove(from: 21, to: 53),
        ];
        final sans = moves.fold<Tuple2<Position<Chess>, List<String>>>(
            const Tuple2(Chess.initial, []), (acc, e) {
          final ret = acc.item1.playToSan(e);
          return Tuple2(ret.item1, [...acc.item2, ret.item2]);
        });
        expect(sans.item2,
            equals(['e4', 'e5', 'Bc4', 'Nc6', 'Qf3', 'd6', 'Qxf7#']));
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
      final moves = {
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
      };
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
        expect(pos.castles.rook[Side.white], equals(const Tuple2(0, null)));
        expect(pos.castles.unmovedRooks.has(7), false);
      });

      test('capturing a rook removes castling right', () {
        final pos = Chess.fromSetup(Setup.parseFen(
                'r1bqk1nr/pppp1pbp/2n1p1p1/8/2B1P3/1P3N2/P1PP1PPP/RNBQK2R b KQkq - 4 4'))
            .play(const NormalMove(from: 54, to: 0));
        expect(pos.castles.rook[Side.white], equals(const Tuple2(null, 7)));
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
        expect(pos.castles.rook[Side.white], equals(const Tuple2(null, null)));
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

    group('perft', () {
      test('initial position', () {
        const pos = Chess.initial;
        expect(perft(pos, 0), 1);
        expect(perft(pos, 1), 20);
        expect(perft(pos, 2), 400);
        expect(perft(pos, 3), 8902);
      });

      test('tricky', () {
        for (final t in [
          [
            'pos-2',
            'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -',
            48,
            2039,
            97862
          ], // Kiwipete by Peter McKenzie
          [
            'pos-3',
            '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - -',
            14,
            191,
            2812,
            43238
          ],
          [
            'pos-4',
            'r2q1rk1/pP1p2pp/Q4n2/bbp1p3/Np6/1B3NBn/pPPP1PPP/R3K2R b KQ -',
            6,
            264,
            9467
          ],
          [
            'pos-5',
            'rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ -',
            44,
            1486,
            62379
          ], // http://www.talkchess.com/forum/viewtopic.php?t=42463
          [
            'pos-6',
            'r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - -',
            46,
            2079,
            89890
          ], // By Steven Edwards

          // http://www.talkchess.com/forum/viewtopic.php?t=55274
          [
            'xfen-00',
            'r1k1r2q/p1ppp1pp/8/8/8/8/P1PPP1PP/R1K1R2Q w KQkq -',
            23,
            522,
            12333,
            285754
          ],
          [
            'xfen-01',
            'r1k2r1q/p1ppp1pp/8/8/8/8/P1PPP1PP/R1K2R1Q w KQkq -',
            28,
            738,
            20218,
            541480
          ],
          [
            'xfen-02',
            '8/8/8/4B2b/6nN/8/5P2/2R1K2k w Q -',
            34,
            318,
            9002,
            118388
          ],
          ['xfen-03', '2r5/8/8/8/8/8/6PP/k2KR3 w K -', 17, 242, 3931, 57700],
          [
            'xfen-04',
            '4r3/3k4/8/8/8/8/6PP/qR1K1R2 w KQ -',
            19,
            628,
            12858,
            405636
          ],

          // Regression tests
          [
            'ep-evasion',
            '8/8/8/5k2/3p4/8/4P3/4K3 w - -',
            6,
            54,
            343,
            2810,
            19228
          ],
          ['prison', '2b5/kpPp4/1p1P4/1P6/6p1/4p1P1/4PpPK/5B2 w - -', 1, 1, 1],
          [
            'king-walk',
            '8/8/8/B2p3Q/2qPp1P1/b7/2P2PkP/4K2R b K -',
            26,
            611,
            14583,
            366807
          ],
          [
            'a1-check',
            '4k3/5p2/5p1p/8/rbR5/1N6/5PPP/5K2 b - - 1 29',
            22,
            580,
            12309
          ],

          // https://github.com/ornicar/lila/issues/4625
          [
            'hside-rook-blocks-aside-castling',
            '4rrk1/pbbp2p1/1ppnp3/3n1pqp/3N1PQP/1PPNP3/PBBP2P1/4RRK1 w Ff -',
            42,
            1743,
            71908,
          ],
        ]) {
          final pos = Chess.fromSetup(Setup.parseFen(t[1] as String));
          expect(perft(pos, 1), t[2]);
          expect(perft(pos, 2), t[3]);
          expect(perft(pos, 3), t[4]);
        }
      });

      test('random', () {
        for (final t in [
          [
            'gentest-1',
            'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -',
            20,
            400,
            8902,
            197281,
            4865609
          ],
          [
            'gentest-2',
            'rnbqkbnr/pp1ppppp/2p5/8/6P1/2P5/PP1PPP1P/RNBQKBNR b KQkq -',
            21,
            463,
            11138,
            274234,
            7290026
          ],
          [
            'gentest-3',
            'rnb1kbnr/ppq1pppp/2pp4/8/6P1/2P5/PP1PPPBP/RNBQK1NR w KQkq -',
            27,
            734,
            20553,
            579004,
            16988496
          ],
          [
            'gentest-4',
            'rnb1kbnr/p1q1pppp/1ppp4/8/4B1P1/2P5/PPQPPP1P/RNB1K1NR b KQkq -',
            28,
            837,
            22536,
            699777,
            19118920
          ],
          [
            'gentest-5',
            'rn2kbnr/p1q1ppp1/1ppp3p/8/4B1b1/2P4P/PPQPPP2/RNB1K1NR w KQkq -',
            29,
            827,
            24815,
            701084,
            21819626
          ],
          [
            'gentest-6',
            'rn1qkbnr/p3ppp1/1ppp2Qp/3B4/6b1/2P4P/PP1PPP2/RNB1K1NR b KQkq -',
            25,
            976,
            23465,
            872551,
            21984216
          ],
          [
            'gentest-7',
            'rnkq1bnr/p3ppp1/1ppp3p/3B4/6b1/2PQ3P/PP1PPP2/RNB1K1NR w KQ -',
            36,
            957,
            33542,
            891412,
            31155934
          ],
          [
            'gentest-8',
            'rnkq1bnr/p3ppp1/1ppp3p/5b2/8/2PQ3P/PP1PPPB1/RNB1K1NR b KQ -',
            29,
            927,
            25822,
            832461,
            23480361
          ],
          [
            'gentest-9',
            'rn1q1bnr/p2kppp1/2pp3p/1p3b2/1P6/2PQ3P/P2PPPB1/RNB1K1NR w KQ -',
            31,
            834,
            25926,
            715605,
            22575950
          ],
          [
            'gentest-10',
            'rn1q1bnr/3kppp1/p1pp3p/1p3b2/1P6/2P2N1P/P1QPPPB1/RNB1K2R b KQ -',
            29,
            900,
            25008,
            781431,
            22075119
          ],
          [
            'gentest-94',
            '2b1kbnB/rppqp3/3p3p/3P1pp1/pnP3P1/PP2P2P/4QP2/RN2KBNR b KQ -',
            27,
            729,
            20665,
            613681,
            18161673
          ],
          [
            'gentest-95',
            '2b1kbnB/r1pqp3/n2p3p/1p1P1pp1/p1P3P1/PP2P2P/Q4P2/RN2KBNR w KQ -',
            30,
            689,
            21830,
            556204,
            18152100
          ],
          [
            'gentest-96',
            '2b1kbn1/r1pqp3/n2p3p/3P1pp1/ppP3P1/PPB1P2P/Q4P2/RN2KBNR b KQ -',
            23,
            685,
            17480,
            532817,
            14672791
          ],
        ]) {
          final pos = Chess.fromSetup(Setup.parseFen(t[1] as String));
          expect(perft(pos, 1), t[2]);
          expect(perft(pos, 2), t[3]);
          expect(perft(pos, 3), t[4]);
          expect(perft(pos, 4), t[5]);
          if (t[6] as int < 100000) {
            expect(perft(pos, 5), t[6]);
          }
        }
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

    test('perft', () {
      for (final t in [
        [
          'atomic-start',
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -',
          20,
          400,
          8902
        ],
        [
          'programfox-2',
          'rn1qkb1r/p5pp/2p5/3p4/N3P3/5P2/PPP4P/R1BQK3 w Qkq -',
          28,
          833,
          23353
        ],
        ['atomic960-castle-1', '8/8/8/8/8/8/2k5/rR4KR w KQ -', 18, 180, 4364],
        ['atomic960-castle-2', 'r3k1rR/5K2/8/8/8/8/8/8 b kq -', 25, 282, 6753],
        [
          'atomic960-castle-3',
          'Rr2k1rR/3K4/3p4/8/8/8/7P/8 w kq -',
          21,
          465,
          10631
        ],
        [
          'shakmaty-bench',
          'rn2kb1r/1pp1p2p/p2q1pp1/3P4/2P3b1/4PN2/PP3PPP/R2QKB1R b KQkq -',
          40,
          1238,
          45237
        ],
        [
          'near-king-explosion',
          'rnbqk2r/pp1p2pp/2p3Nn/5p2/1b2P1PP/8/PPP2P2/R1BQKB1R w KQkq -',
          5,
          132,
          4973
        ],
      ]) {
        final pos = Atomic.fromSetup(Setup.parseFen(t[1] as String));
        expect(perft(pos, 1), t[2]);
        expect(perft(pos, 2), t[3]);
        expect(perft(pos, 3), t[4]);
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

    test('perft', () {
      for (final t in [
        [
          'antichess-start',
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w - -',
          20,
          400,
          8067
        ],
        ['a-pawn-vs-b-pawn', '8/1p6/8/8/8/8/P7/8 w - -', 2, 4, 4],
        ['a-pawn-vs-c-pawn', '8/2p5/8/8/8/8/P7/8 w - -', 2, 4, 4],
      ]) {
        final pos = Antichess.fromSetup(Setup.parseFen(t[1] as String));
        expect(perft(pos, 1), t[2]);
        expect(perft(pos, 2), t[3]);
        expect(perft(pos, 3), t[4]);
      }
    });

    test('en passant', () {
      final setup = Setup.parseFen(
          'r1bqkbn1/p1ppp3/2n4p/6p1/1Pp5/4P3/P2P1PP1/R1B1K3 b - b3 0 11');
      final pos = Antichess.fromSetup(setup);
      final move = Move.fromUci('c4b3');
      expect(pos.isLegal(move), isTrue);

      // TODO uncomment when parseSan is implemented
      // final sanMove = pos.parseSan('cxb3');
      // expect(move, equals(sanMove));
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

    test('perft', () {
      for (final t in [
        [
          'zh-all-drop-types',
          '2k5/8/8/8/8/8/8/4K3[QRBNPqrbnp] w - -',
          301,
          75353,
          null
        ],
        ['zh-drops', '2k5/8/8/8/8/8/8/4K3[Qn] w - -', 67, 3083, 88634],
        [
          'zh-middlegame',
          'r1bqk2r/pppp1ppp/2n1p3/4P3/1b1Pn3/2NB1N2/PPP2PPP/R1BQK2R[] b KQkq -',
          42,
          1347,
          58057,
        ],
        ['zh-promoted', '4k3/1Q~6/8/8/4b3/8/Kpp5/8/ b - -', 20, 360, 5445],
      ]) {
        final pos = Crazyhouse.fromSetup(Setup.parseFen(t[1]! as String));
        expect(perft(pos, 1), t[2]);
        expect(perft(pos, 2), t[3]);
        if (t[4] != null) {
          expect(perft(pos, 3), t[4]);
        }
      }
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
      expect(pos.play(Move.fromUci('f1b5')).fen,
          'rnbqkbnr/ppp1pppp/3p4/1B6/8/4P3/PPPP1PPP/RNBQK1NR b KQkq - 2+3 1 2');
    });

    test('perft', () {
      for (final t in [
        [
          'kiwipete',
          'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 1+1',
          48,
          2039,
          97848
        ],
        ['castling', 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 1+1', 26, 562, 13410],
      ]) {
        final pos = ThreeCheck.fromSetup(Setup.parseFen(t[1] as String));
        expect(perft(pos, 1), t[2]);
        expect(perft(pos, 2), t[3]);
        expect(perft(pos, 3), t[4]);
      }
    });
  });
}
