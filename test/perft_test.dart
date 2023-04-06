@Tags(['perft'])
import 'package:test/test.dart';
import 'dart:io';
import 'package:dartchess/dartchess.dart';

class Perft {
  String id;
  String fen;
  List<TestCase> cases;

  Perft(this.id, this.fen, this.cases);
}

class TestCase {
  int depth;
  int nodes;

  TestCase(this.depth, this.nodes);
}

class Parser {
  List<Perft> parse(String input) {
    final lines = input.split('\n');
    final perftBlocks = _splitBlocks(lines).map(_parsePerft);
    return perftBlocks.toList();
  }

  static Iterable<List<String>> _splitBlocks(List<String> lines) sync* {
    final block = <String>[];
    for (final line in lines) {
      if (line.startsWith('#')) {
        continue; // Ignore comments and blank lines
      }

      if (line.trim().isEmpty && block.isNotEmpty) {
        yield block.toList();
        block.clear();
      }

      if (line.isNotEmpty) {
        block.add(line);
      }
    }
    if (block.isNotEmpty) {
      yield block.toList();
    }
  }

  static Perft _parsePerft(List<String> block) {
    final id = block[0].substring(3);
    final epd = block[1].substring(3).trim();
    final cases = block.skip(2).map(_parseTestCase);
    return Perft(id, epd, cases.toList());
  }

  static TestCase _parseTestCase(String line) {
    final parts = line.trim().split(RegExp('\\s+'));
    final depth = int.parse(parts[1]);
    final nodes = int.parse(parts[2]);
    return TestCase(depth, nodes);
  }
}

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
