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
}
