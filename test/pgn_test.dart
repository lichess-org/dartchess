import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';




void main() {
  test('make pgn', () {
    var root = Node<PgnNodeData>(null);
    var e4 = Node<PgnNodeData>(PgnNodeData(san: 'e4', nags: [7]));
    var e3 = Node<PgnNodeData>(PgnNodeData(san: 'e3'));
    root.children.add(e4);
    root.children.add(e3);
    var e5 = Node<PgnNodeData>(PgnNodeData(san: 'e5'));
    var e6 = Node<PgnNodeData>(PgnNodeData(san: 'e6'));
    e4.children.add(e5);
    e4.children.add(e6);
    var nf3 =
        Node<PgnNodeData>(PgnNodeData(san: 'Nf3', comments: ['a comment']));
    e6.children.add(nf3);
    var c4 = Node<PgnNodeData>(PgnNodeData(san: 'c4'));
    e5.children.add(c4);

    expect(makePgn(Game(headers: {}, moves: root)),
        "1. e4 \$7 ( 1. e3 ) 1... e5 ( 1... e6 2. Nf3 { a comment } ) 2. c4 *\n");
  });

  test('parse headers', () {
    var games = parsePgn([
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

      final game = parsePgn('1. a4 ( 1. b4 b5 -- ) 1... a5')[0];
      //print(game.moves.children[0].children[0].data!.san);
  });
}
