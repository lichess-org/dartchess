import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';
import 'dart:io';

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
    expect(games[0].headers['Escaped'],
        'quote: ", backslashes: \\\\, trailing text');
    expect(games[0].headers['Multiple'], 'on');
    expect(games[0].headers['the'], 'same line');
    expect(games[0].headers['Result'], '*');
    expect(games[0].headers['Event'], '?');
  });

  test('parse pgn roundtrip', () {
    const pgn = '1. e4 \ne5\nNf3 {foo\n  bar baz } 1-0';
    final List<Game<PgnNodeData>> games = [];
    void callback(Game<PgnNodeData> game, [Exception? error]) {
      games.add(game);
    }

    PgnParser(callback, emptyHeaders).parse(pgn);
    expect(makePgn(games[0]),
        '[Result "1-0"]\n\n1. e4 e5 2. Nf3 { foo\n  bar baz } 1-0\n');
  });

  test('tricky tokens', () {
    final steps = parsePgn('O-O-O !! 0-0-0# ??')[0].moves.mainline().toList();
    expect(steps[0].san, 'O-O-O');
    expect(steps[0].nags, [3]);
    expect(steps[1].san, 'O-O-O#');
    expect(steps[1].nags, [4]);
  });

  test('pgn file - kasparov-deep-blue-1997', () {
    final String data =
        File('./data/kasparov-deep-blue-1997.pgn').readAsStringSync();
    final List<Game<PgnNodeData>> games = parsePgn(data);
    expect(games.length, 6);
  });

  test('pgn file - leading-whitespace', () {
    final String data =
        File('./data/leading-whitespace.pgn').readAsStringSync();
    final List<Game<PgnNodeData>> games = parsePgn(data);
    expect(games[0].moves.mainline().map((move) => move.san).toList(),
        ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5']);
    expect(games.length, 4);
  });

  test('pgn file - headers-and-moves-on-the-same-line', () {
    final String data = File('./data/headers-and-moves-on-the-same-line.pgn')
        .readAsStringSync();
    final List<Game<PgnNodeData>> games = parsePgn(data);
    expect(games[0].headers['Variant'], 'Antichess');
    expect(games[1].moves.mainline().map((move) => move.san).toList(),
        ['e3', 'e6', 'b4', 'Bxb4', 'Qg4']);
    expect(games.length, 3);
  });

  test('pgn file - pathological-headers', () {
    final String data =
        File('./data/pathological-headers.pgn').readAsStringSync();
    final List<Game<PgnNodeData>> games = parsePgn(data);
    expect(games[0].headers['A'], 'b"');
    expect(games[0].headers['B'], 'b"');
    expect(games[0].headers['C'], 'A]]');
    expect(games[0].headers['D'], 'A]][');
    expect(games[0].headers['E'], '"A]]["');
    expect(games[0].headers['F'], '"A]]["\\');
    expect(games[0].headers['G'], '"]');
    expect(games.length, 1);
  });

  test('parse comment', () {
    expect(
        parseComment('[%eval -0.42] suffix'),
        const Comment(
          text: 'suffix',
          eval: Evaluation.pawns(pawns: -0.42),
        ));

    expect(
        parseComment('prefix [%emt 1:02:03.4]'),
        const Comment(
          text: 'prefix',
          emt: 3723.4,
        ));

    expect(
        parseComment('[%csl Ya1][%cal Ra1a1,Be1e2]commentary [%csl Gh8]'),
        const Comment(text: 'commentary', shapes: [
          CommentShape(color: CommentShapeColor.yellow, from: 0, to: 0),
          CommentShape(color: CommentShapeColor.red, from: 0, to: 0),
          CommentShape(color: CommentShapeColor.blue, from: 4, to: 12),
          CommentShape(color: CommentShapeColor.green, from: 63, to: 63)
        ]));

    expect(
        parseComment('prefix [%eval .99,23]'),
        const Comment(
            text: 'prefix', eval: Evaluation.pawns(pawns: 0.99, depth: 23)));

    expect(
        parseComment('[%eval #-3] suffix'),
        const Comment(
          text: 'suffix',
          eval: Evaluation.mate(mate: -3),
        ));

    expect(
        parseComment('[%csl Ga1]foo'),
        const Comment(text: 'foo', shapes: [
          CommentShape(color: CommentShapeColor.green, from: 0, to: 0)
        ]));

    expect(
        parseComment('foo [%bar] [%csl Ga1] [%cal Ra1h1,Gb1b8] [%clk 3:25:45]')
            .text,
        'foo [%bar]');
  });

  test('make comment', () {
    expect(
        makeComment(const Comment(
            text: 'text',
            emt: 3723.4,
            eval: Evaluation.pawns(pawns: 10),
            clock: 1,
            shapes: [
              CommentShape(color: CommentShapeColor.yellow, from: 0, to: 0),
              CommentShape(color: CommentShapeColor.red, from: 0, to: 1),
              CommentShape(color: CommentShapeColor.red, from: 0, to: 2)
            ])),
        'text [%csl Ya1] [%cal Ra1b1,Ra1c1] [%eval 10.00] [%emt 1:02:03.4] [%clk 0:00:01]');

    expect(
        makeComment(const Comment(eval: Evaluation.mate(mate: -4, depth: 5))),
        '[%eval #-4,5]');
  });

  test('roundtrip comment', () {
    final comments = [
      '[%csl[%eval 0.2] Ga1]',
      '[%c[%csl [%csl Ga1[%csl Ga1][%[%csl Ga1][%cal[%csl Ga1]Ra1]',
      '[%csl Ga1][%cal Ra1h1,Gb1b8] foo [%clk 3:ê5: [%eval 450752] [%evaÿTæ<92>ÿÿ^?,7]',
    ];

    for (final str in comments) {
      final comment = parseComment(str);
      final roundTripped = parseComment(makeComment(comment));
      expect(comment, roundTripped);
    }
  });
}
