import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('Pgn', () {
    test('make pgn', () {
      final root = PgnNode<PgnNodeData>();
      final e4 =
          PgnChildNode<PgnNodeData>(const PgnNodeData(san: 'e4', nags: [7]));
      final e3 = PgnChildNode<PgnNodeData>(const PgnNodeData(san: 'e3'));
      root.children.add(e4);
      root.children.add(e3);
      final e5 = PgnChildNode<PgnNodeData>(const PgnNodeData(san: 'e5'));
      final e6 = PgnChildNode<PgnNodeData>(const PgnNodeData(san: 'e6'));
      e4.children.add(e5);
      e4.children.add(e6);
      final nf3 = PgnChildNode<PgnNodeData>(
          const PgnNodeData(san: 'Nf3', comments: ['a comment']));
      e6.children.add(nf3);
      final c4 = PgnChildNode<PgnNodeData>(const PgnNodeData(san: 'c4'));
      e5.children.add(c4);

      expect(
          PgnGame(headers: const {}, moves: root, comments: const []).makePgn(),
          '1. e4 \$7 ( 1. e3 ) 1... e5 ( 1... e6 2. Nf3 { a comment } ) 2. c4 *\n');
    });

    test('make pgn from empty game', () {
      final game =
          PgnGame(headers: {}, moves: PgnNode<PgnNodeData>(), comments: []);
      expect(game.makePgn(), '*\n');
    });

    test('parse headers', () {
      final game = PgnGame.parsePgn([
        '[Black "black player"]',
        '[White " white  player   "]',
        '[Escaped "quote: \\", backslashes: \\\\\\\\, trailing text"]',
        '[Multiple "on"] [the "same line"]',
        '[Incomplete',
      ].join('\r\n'));

      expect(game.headers['Black'], 'black player');
      expect(game.headers['White'], ' white  player   ');
      expect(game.headers['Escaped'],
          'quote: ", backslashes: \\\\, trailing text');
      expect(game.headers['Multiple'], 'on');
      expect(game.headers['the'], 'same line');
      expect(game.headers['Result'], '*');
      expect(game.headers['Event'], '?');
    });

    test('parse emtpy pgn', () {
      final games = PgnGame.parseMultiGamePgn('');
      expect(games.length, 0);

      // expect(game.headers, PgnGame.defaultHeaders());
      // expect(game.moves.children.length, 0);
    });

    test('parse pgn roundtrip', () {
      const pgn = '1. e4 \ne5\nNf3 {foo\n  bar baz } 1-0';
      final game = PgnGame.parsePgn(pgn, initHeaders: PgnGame.emptyHeaders);

      expect(game.makePgn(),
          '[Result "1-0"]\n\n1. e4 e5 2. Nf3 { foo\n  bar baz } 1-0\n');
    });

    test('tricky tokens', () {
      final steps =
          PgnGame.parsePgn('O-O-O !! 0-0-0# ??').moves.mainline().toList();
      expect(steps[0].san, 'O-O-O');
      expect(steps[0].nags, [3]);
      expect(steps[1].san, 'O-O-O#');
      expect(steps[1].nags, [4]);
    });

    test('pgn file - kasparov-deep-blue-1997', () {
      final String data =
          File('./data/kasparov-deep-blue-1997.pgn').readAsStringSync();
      final List<PgnGame<PgnNodeData>> games = PgnGame.parseMultiGamePgn(data);
      expect(games.length, 6);
    });

    test('pgn file - specify empty headers', () {
      final String data =
          File('./data/kasparov-deep-blue-1997.pgn').readAsStringSync();
      final List<PgnGame<PgnNodeData>> games =
          PgnGame.parseMultiGamePgn(data, initHeaders: () => {});
      expect(games.length, 6);
    });

    test('pgn file - leading-whitespace', () {
      final String data =
          File('./data/leading-whitespace.pgn').readAsStringSync();
      final List<PgnGame<PgnNodeData>> games = PgnGame.parseMultiGamePgn(data);
      expect(games[0].moves.mainline().map((move) => move.san).toList(),
          ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5']);
      expect(games.length, 4);
    });

    test('pgn file - headers-and-moves-on-the-same-line', () {
      final String data = File('./data/headers-and-moves-on-the-same-line.pgn')
          .readAsStringSync();
      final List<PgnGame<PgnNodeData>> games = PgnGame.parseMultiGamePgn(data);
      expect(games[0].headers['Variant'], 'Antichess');
      expect(games[1].moves.mainline().map((move) => move.san).toList(),
          ['e3', 'e6', 'b4', 'Bxb4', 'Qg4']);
      expect(games.length, 3);
    });

    test('pgn file - pathological-headers', () {
      final String data =
          File('./data/pathological-headers.pgn').readAsStringSync();
      final List<PgnGame<PgnNodeData>> games = PgnGame.parseMultiGamePgn(data);
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
          PgnComment.fromPgn('[%eval -0.42] suffix'),
          const PgnComment(
            text: 'suffix',
            eval: PgnEvaluation.pawns(pawns: -0.42),
          ));

      expect(
          PgnComment.fromPgn('prefix [%emt 1:02:03.4]'),
          const PgnComment(
            text: 'prefix',
            emt: Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 400),
          ));

      expect(
          PgnComment.fromPgn(
              '[%csl Ya1][%cal Ra1a1,Be1e2]commentary [%csl Gh8]'),
          const PgnComment(text: 'commentary', shapes: [
            PgnCommentShape(color: CommentShapeColor.yellow, from: 0, to: 0),
            PgnCommentShape(color: CommentShapeColor.red, from: 0, to: 0),
            PgnCommentShape(color: CommentShapeColor.blue, from: 4, to: 12),
            PgnCommentShape(color: CommentShapeColor.green, from: 63, to: 63)
          ]));

      expect(
          PgnComment.fromPgn('[%eval -0.42] suffix'),
          const PgnComment(
            text: 'suffix',
            eval: PgnEvaluation.pawns(pawns: -0.42),
          ));
      expect(
          PgnComment.fromPgn('prefix [%eval .99,23]'),
          const PgnComment(
              text: 'prefix',
              eval: PgnEvaluation.pawns(pawns: 0.99, depth: 23)));

      expect(
          PgnComment.fromPgn('[%eval #-3] suffix'),
          const PgnComment(
            text: 'suffix',
            eval: PgnEvaluation.mate(mate: -3),
          ));

      expect(
          PgnComment.fromPgn('[%csl Ga1]foo'),
          const PgnComment(text: 'foo', shapes: [
            PgnCommentShape(color: CommentShapeColor.green, from: 0, to: 0)
          ]));

      expect(
          PgnComment.fromPgn(
                  'foo [%bar] [%csl Ga1] [%cal Ra1h1,Gb1b8] [%clk 3:25:45]')
              .text,
          'foo [%bar]');
    });

    test('make comment', () {
      expect(
          const PgnComment(
              text: 'text',
              emt:
                  Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 400),
              eval: PgnEvaluation.pawns(pawns: 10),
              clock: Duration(seconds: 1),
              shapes: [
                PgnCommentShape(
                    color: CommentShapeColor.yellow, from: 0, to: 0),
                PgnCommentShape(color: CommentShapeColor.red, from: 0, to: 1),
                PgnCommentShape(color: CommentShapeColor.red, from: 0, to: 2)
              ]).makeComment(),
          'text [%csl Ya1] [%cal Ra1b1,Ra1c1] [%eval 10.00] [%emt 1:02:03.4] [%clk 0:00:01]');

      expect(
          const PgnComment(eval: PgnEvaluation.mate(mate: -4, depth: 5))
              .makeComment(),
          '[%eval #-4,5]');
    });

    test('roundtrip comment', () {
      final comments = [
        '[%csl[%eval 0.2] Ga1]',
        '[%c[%csl [%csl Ga1[%csl Ga1][%[%csl Ga1][%cal[%csl Ga1]Ra1]',
        '[%csl Ga1][%cal Ra1h1,Gb1b8] foo [%clk 3:ê5: [%eval 450752] [%evaÿTæ<92>ÿÿ^?,7]',
      ];

      for (final str in comments) {
        final comment = PgnComment.fromPgn(str);
        final roundTripped = PgnComment.fromPgn(comment.makeComment());
        expect(comment, roundTripped);
      }
    });

    group('Invalid Pgns', () {
      test('Pgn with only correct first move', () {
        final game = PgnGame.parsePgn('1. e4 ads');
        expect(game.moves.children.length, 1);
      });

      test('Wrong move in Sideline, Should Ignore it', () {
        final game = PgnGame.parsePgn(
            '1. e4 c5 (1... adsd 2. Nc3) (1... d5 2. d3) 2. Nf3 d5');
        expect(game.moves.children[0].children.length, 3);
        expect(game.moves.children[0].children[1].data.san, 'Nc3');
      });
    });

    test('transform pgn', () {
      final game = PgnGame.parsePgn('1. a4 ( 1. b4 b5 -- ) 1... a5');
      final PgnNode<PgnNodeWithFen> res =
          game.moves.transform<PgnNodeWithFen, Position>(
        PgnGame.startingPosition(game.headers),
        (pos, data, _) {
          final move = pos.parseSan(data.san);
          if (move != null) {
            final pos2 = pos.play(move);
            return (pos2, PgnNodeWithFen(fen: pos2.fen, data: data));
          }
          return null;
        },
      );

      expect(res.children[0].data.fen,
          'rnbqkbnr/pppppppp/8/8/P7/8/1PPPPPPP/RNBQKBNR b KQkq - 0 1');
      expect(res.children[0].children[0].data.fen,
          'rnbqkbnr/1ppppppp/8/p7/P7/8/1PPPPPPP/RNBQKBNR w KQkq - 0 2');
      expect(res.children[1].data.fen,
          'rnbqkbnr/pppppppp/8/8/1P6/8/P1PPPPPP/RNBQKBNR b KQkq - 0 1');
      expect(res.children[1].children[0].data.fen,
          'rnbqkbnr/p1pppppp/8/1p6/1P6/8/P1PPPPPP/RNBQKBNR w KQkq - 0 2');
    });
  });
}

class PgnNodeWithFen {
  final String fen;
  // ignore: unreachable_from_main
  final PgnNodeData data;
  const PgnNodeWithFen({required this.fen, required this.data});
}
