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
