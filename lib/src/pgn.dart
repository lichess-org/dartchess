
class PgnNodeData {
  final String san;
  List<String>? startingComments;
  List<String>? comments;
  List<int>? nags;
  PgnNodeData(this.san);
}

class Node<T> {
  List<ChildNode<T>> children = [];

  Iterable<T> mainline() sync* {
    var node = this;
    while (node.children.isNotEmpty) {
      var child = node.children[0];
      yield child.data;
      node = child;
    }
  }
}

class ChildNode<T> extends Node<T> {
  T data;
  ChildNode(this.data);
}

class Game<T> {
  Map<String, String> headers;
  List<String> comments = [];
  Node<T> moves;

  Game(Map<String, String> header, Node<T> move)
      : headers = header,
        moves = move;
}

class ParserFrame {
  Node<PgnNodeData> parent;
  bool root;
  ChildNode<PgnNodeData>? node;
  List<String>? startingComments;

  ParserFrame(this.parent, this.root);
}

enum ParserState { bom, pre, headers, moves, comment }

enum PgnState { pre, sidelines, end }

class PgnFrame {
  PgnState state;
  int ply;
  ChildNode<PgnNodeData> node;
  Iterable<ChildNode<PgnNodeData>> sidelines;
  bool startsVariation;
  bool inVariation;

  PgnFrame(this.state, this.ply, this.node, this.sidelines,
      this.startsVariation, this.inVariation);
}

Map<String, String> defaultHeaders() => {
      'Event': '?',
      'Site': '?',
      'Date': '????.??.??',
      'Round': '?',
      'White': '?',
      'Black': '?',
      'Result': '*'
    };
