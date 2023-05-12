@Tags(['full_perft'])
library;

import 'package:test/test.dart';
import 'dart:io';
import 'package:dartchess/dartchess.dart';
import 'perft_parser.dart';

void main() async {
  group('Three Check', () {
    final tests =
        Parser().parse(File('test/resources/3check.perft').readAsStringSync());
    for (final perftTest in tests) {
      final position = ThreeCheck.fromSetup(Setup.parseFen(perftTest.fen));
      for (final testCase in perftTest.cases) {
        test('${perftTest.id} ${perftTest.fen} ${testCase.depth}', () {
          expect(perft(position, testCase.depth), testCase.nodes,
              reason:
                  'id: ${perftTest.id}\nfen: ${perftTest.fen} \ndepth: ${testCase.depth} \nnodes: ${testCase.nodes}');
        });
      }
    }
  });

  group('Antichess', () {
    final tests = Parser()
        .parse(File('test/resources/antichess.perft').readAsStringSync());
    for (final perftTest in tests) {
      final position = Antichess.fromSetup(Setup.parseFen(perftTest.fen));
      for (final testCase in perftTest.cases) {
        test('${perftTest.id} ${perftTest.fen} ${testCase.depth}', () {
          expect(perft(position, testCase.depth), testCase.nodes,
              reason:
                  'id: ${perftTest.id}\nfen: ${perftTest.fen} \ndepth: ${testCase.depth} \nnodes: ${testCase.nodes}');
        });
      }
    }
  });

  group('Atomic', () {
    final tests =
        Parser().parse(File('test/resources/atomic.perft').readAsStringSync());
    for (final perftTest in tests) {
      final position = Atomic.fromSetup(Setup.parseFen(perftTest.fen));
      for (final testCase in perftTest.cases) {
        test('${perftTest.id} ${perftTest.fen} ${testCase.depth}', () {
          expect(perft(position, testCase.depth), testCase.nodes,
              reason:
                  'id: ${perftTest.id}\nfen: ${perftTest.fen} \ndepth: ${testCase.depth} \nnodes: ${testCase.nodes}');
        });
      }
    }
  });

  group('Crazyhouse', () {
    final tests = Parser()
        .parse(File('test/resources/crazyhouse.perft').readAsStringSync());
    for (final perftTest in tests) {
      final position = Crazyhouse.fromSetup(Setup.parseFen(perftTest.fen));
      for (final testCase in perftTest.cases) {
        test('${perftTest.id} ${perftTest.fen} ${testCase.depth}', () {
          expect(perft(position, testCase.depth), testCase.nodes,
              reason:
                  'id: ${perftTest.id}\nfen: ${perftTest.fen} \ndepth: ${testCase.depth} \nnodes: ${testCase.nodes}');
        });
      }
    }
  });

  group('Horde', () {
    final tests =
        Parser().parse(File('test/resources/horde.perft').readAsStringSync());
    for (final perftTest in tests) {
      final position = Horde.fromSetup(Setup.parseFen(perftTest.fen));
      for (final testCase in perftTest.cases) {
        test('${perftTest.id} ${perftTest.fen} ${testCase.depth}', () {
          expect(perft(position, testCase.depth), testCase.nodes,
              reason:
                  'id: ${perftTest.id}\nfen: ${perftTest.fen} \ndepth: ${testCase.depth} \nnodes: ${testCase.nodes}');
        });
      }
    }
  });

  group('Racing Kings', () {
    final tests = Parser()
        .parse(File('test/resources/racingkings.perft').readAsStringSync());
    for (final perftTest in tests) {
      final position = RacingKings.fromSetup(Setup.parseFen(perftTest.fen));
      for (final testCase in perftTest.cases) {
        test('${perftTest.id} ${perftTest.fen} ${testCase.depth}', () {
          expect(perft(position, testCase.depth), testCase.nodes,
              reason:
                  'id: ${perftTest.id}\nfen: ${perftTest.fen} \ndepth: ${testCase.depth} \nnodes: ${testCase.nodes}');
        });
      }
    }
  });

  group('Chess Tricky', () {
    final tests =
        Parser().parse(File('test/resources/tricky.perft').readAsStringSync());
    for (final perftTest in tests) {
      for (final testCase in perftTest.cases) {
        test('${perftTest.id} ${perftTest.fen} ${testCase.depth}', () {
          final position = Chess.fromSetup(Setup.parseFen(perftTest.fen),
              ignoreImpossibleCheck:
                  true); // true: otherwise there is an Impossible Check Error
          expect(perft(position, testCase.depth), testCase.nodes,
              reason:
                  'id: ${perftTest.id}\nfen: ${perftTest.fen} \ndepth: ${testCase.depth} \nnodes: ${testCase.nodes}');
        });
      }
    }
  });

  group('Random', () {
    final tests =
        Parser().parse(File('test/resources/random.perft').readAsStringSync());
    // only test 25 position in random. Test file has around 6000 positions
    for (final perftTest in tests.take(25)) {
      final position = Chess.fromSetup(Setup.parseFen(perftTest.fen));
      for (final testCase in perftTest.cases) {
        test('${perftTest.id} ${perftTest.fen}  ${testCase.depth}', () {
          expect(perft(position, testCase.depth), testCase.nodes,
              reason:
                  'id: ${perftTest.id}\nfen: ${perftTest.fen} \ndepth: ${testCase.depth} \nnodes: ${testCase.nodes}');
        });
      }
    }
  });

  group('Chess 960', () {
    final tests = Parser()
        .parse(File('test/resources/chess960.perft').readAsStringSync());
    for (final perftTest in tests) {
      final position = Chess.fromSetup(Setup.parseFen(perftTest.fen));
      for (final testCase in perftTest.cases) {
        test('${perftTest.id} ${perftTest.fen} ${testCase.depth}', () {
          expect(perft(position, testCase.depth), testCase.nodes,
              reason:
                  'id: ${perftTest.id}\nfen: ${perftTest.fen} \ndepth: ${testCase.depth} \nnodes: ${testCase.nodes}');
        });
      }
    }
  });
}
