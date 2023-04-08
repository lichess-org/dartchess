@Tags(['perft'])
import 'package:test/test.dart';
import 'dart:io';
import 'package:dartchess/dartchess.dart';
import 'perft_parser.dart';

void main() async {
  var tests =
      Parser().parse(File('test/resources/3check.perft').readAsStringSync());

  group('Three Check', () {
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
  tests = Parser()
      .parse(await File('test/resources/antichess.perft').readAsString());

  group('Antichess', () {
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
  tests =
      Parser().parse(await File('test/resources/atomic.perft').readAsString());

  group('Atomic', () {
    for (final perftTest in tests) {
      final position = Atomic.fromSetup(Setup.parseFen(perftTest.fen));
      for (final testCase in perftTest.cases) {
        test('Atomic ${perftTest.id} ${perftTest.fen} ${testCase.depth}', () {
          expect(perft(position, testCase.depth), testCase.nodes,
              reason:
                  'id: ${perftTest.id}\nfen: ${perftTest.fen} \ndepth: ${testCase.depth} \nnodes: ${testCase.nodes}');
        });
      }
    }
  });
  tests = Parser()
      .parse(await File('test/resources/crazyhouse.perft').readAsString());

  group('Crazyhouse', () {
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
  tests =
      Parser().parse(await File('test/resources/horde.perft').readAsString());

  group('Horde', () {
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
  tests = Parser()
      .parse(await File('test/resources/racingkings.perft').readAsString());

  group('Racing Kings', () {
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
  tests =
      Parser().parse(await File('test/resources/tricky.perft').readAsString());

  group('Chess Tricky', () {
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
  tests =
      Parser().parse(await File('test/resources/random.perft').readAsString());

  group('Random', () {
    for (final perftTest in tests) {
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

  tests = Parser()
      .parse(await File('test/resources/chess960.perft').readAsString());
  group('Chess 960', () {
    for (final perftTest in tests) {
      final position = Chess.fromSetup(Setup.parseFen(perftTest.fen));
      for (final testCase in perftTest.cases) {
        test('Chess 960 ${perftTest.id} ${perftTest.fen} ${testCase.depth}',
            () {
          expect(perft(position, testCase.depth), testCase.nodes,
              reason:
                  'id: ${perftTest.id}\nfen: ${perftTest.fen} \ndepth: ${testCase.depth} \nnodes: ${testCase.nodes}');
        });
      }
    }
  });
}
