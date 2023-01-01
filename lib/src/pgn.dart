import './models.dart';
import "./position.dart";

// Comment: Could we include a parent variable?
// Comment: Do we want to separate ChildNode and Node?
//   The idea here is that data becomes T? data
// Comment: Is a separate walk function required if we have the transform function?
class Node<T> {
  List<ChildNode> children = [];
  Node(this.children);
  Node<U> transform<U>(U f(T)) {
    return Node(this
        .children
        .map((child) => ChildNode(
            f(child.data), child.children.map((child) => child.transform(f))))
        .toList());
  }
}

// Comment: Do we want a ChildNode specific transform function here?
// Without a ChildNode specific implementation, transform returns Node
class ChildNode<T> extends Node<T> {
  T data;
  ChildNode(this.data, children) : super(children);
}

class Game {
  final Map<String, String> headers;
  final List<String> comments;
  final List<Node> moves;

  Game(this.headers, this.comments, this.moves);

  final Game emptyGame = Game({}, [], []);
}

class PgnNodeData {
  String san;
  // Comment: Optional list or just a list that could be empty
  List<String>? startingComments;
  List<String>? comments;
  // Comment: Number type?
  List<num>? nags;

  PgnNodeData(this.san, [this.startingComments, this.comments, this.nags]);
}

String makeOutcome(Outcome outcome) {
  if (outcome.winner == Side.white) {
    return "1-0";
  }
  if (outcome.winner == Side.black) {
    return "0-1";
  }
  return "1/2-1/2";
}

Outcome? parseOutcome(String string) {
  if (string == "1-0") {
    return Outcome.whiteWins;
  }
  if (string == "0-1") {
    return Outcome.blackWins;
  }
  if (string == "1/2-1/2") {
    return Outcome.draw;
  }
}
