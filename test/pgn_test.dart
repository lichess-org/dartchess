import 'dart:convert';

import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';
import 'dart:io';

typedef GameCallBack = void Function(Game<PgnNodeData>, [Error]);

void testPgnFile(String filename, int numGames, bool allValid) {
  test('pgn file - $filename', () async {
    final file = File('./data/$filename.pgn');
    Stream<String> lines = file.openRead().transform(utf8.decoder);

    void gameCallBack(Game<PgnNodeData> game, [Error? err]) {
      if (allValid) expect(err, null);
    }

    final parser = PgnParser(gameCallBack, emptyHeaders);
    try {
      await for (final line in lines) {
        parser.parse(line, stream: true);
      }
      parser.parse('');
    } catch (e) {
      print('Error $e');
    }
  });
}

void main() {
  test('make pgn', () {
    final root = Node<PgnNodeData>();
    final e4 = ChildNode<PgnNodeData>(PgnNodeData(san: 'e4', nags: [7]));
    final e3 = ChildNode<PgnNodeData>(PgnNodeData(san: 'e3'));
    root.children.add(e4);
    root.children.add(e3);
    final e5 = ChildNode<PgnNodeData>(PgnNodeData(san: 'e5'));
    final e6 = ChildNode<PgnNodeData>(PgnNodeData(san: 'e6'));
    e4.children.add(e5);
    e4.children.add(e6);
    final nf3 = ChildNode<PgnNodeData>(
        PgnNodeData(san: 'Nf3', comments: ['a comment']));
    e6.children.add(nf3);
    final c4 = ChildNode<PgnNodeData>(PgnNodeData(san: 'c4'));
    e5.children.add(c4);

    expect(makePgn(Game(headers: const {}, moves: root, comments: const [])),
        "1. e4 \$7 ( 1. e3 ) 1... e5 ( 1... e6 2. Nf3 { a comment } ) 2. c4 *\n");
  });

  test('parse headers', () {
    final games = parsePgn([
      '[Black "black player"]',
      '[White " white  player   "]',
      '[Escaped "quote: \\", backslashes: \\\\\\\\, trailing text"]',
      '[Multiple "on"] [the "same line"]',
      '[Incomplete',
    ].join('\r\n'));

    expect(games.length, 1);
    expect(games[0].headers['Black'], 'black player');
    expect(games[0].headers['White'], ' white  player   ');
    //expect(games[0].headers['Escaped'],
    //    'quote: ", backslashes: \\\\, trailing text');
    expect(games[0].headers['Multiple'], 'on');
    expect(games[0].headers['the'], 'same line');
    expect(games[0].headers['Result'], '*');
    expect(games[0].headers['Event'], '?');
  });

  test('parse pgn', () {
    // Look at creating mock function.
    // One way is to use package mockito but it only supports mocking classes
    void callback(Game<PgnNodeData> game, [Error? error]) {
      expect(makePgn(game),
          '[Result "1-0"]\n\n1. e4 e5 2. Nf3 { foo\n  bar baz } 1-0\n');
    }

    final parser = PgnParser(callback, emptyHeaders);
    parser.parse('1. e4 \ne5', stream: true);
    parser.parse('\nNf3 {foo\n', stream: true);
    parser.parse('  bar baz } 1-', stream: true);
    parser.parse('', stream: true);
    parser.parse('0', stream: true);
    parser.parse('');
  });

  test('tricky tokens', () {
    final steps = parsePgn('O-O-O !! 0-0-0# ??')[0].moves.mainline().toList();
    expect(steps[0].san, 'O-O-O');
    expect(steps[0].nags, [3]);
    expect(steps[1].san, 'O-O-O#');
    expect(steps[1].nags, [4]);
  });

  testPgnFile('kasparov-deep-blue-1997', 6, true);
}
