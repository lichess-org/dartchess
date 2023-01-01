import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';


void main(){
  test('make pgn', (){
     var root = Node<PgnNodeData>();
     var e4 = ChildNode<PgnNodeData>(PgnNodeData(san: 'e4'));
     var e5 = ChildNode<PgnNodeData>(PgnNodeData(san: 'e5'));
     var e3 = ChildNode<PgnNodeData>(PgnNodeData(san: 'e3'));
     var e6 = ChildNode<PgnNodeData>(PgnNodeData(san: 'e6'));
     var nf3 = ChildNode<PgnNodeData>(PgnNodeData(san: 'nf3', comments: ['a comment']));
     var c4 = ChildNode<PgnNodeData>(PgnNodeData(san: 'c4'));

     root.children.add(e4);
     root.children.add(e3);
     e4.children.add(e5);
     e4.children.add(e6);
     e6.children.add(nf3);
     e5.children.add(c4);
     expect(makePgn(Game({}, root)), '1. e4 \$7 ( 1. e3 ) 1... e5 ( 1... e6 2. Nf3 { a comment } ) 2. c4 *\n');

  });
}
