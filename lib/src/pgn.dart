import './setup.dart';
import './models.dart';
import './position.dart';

class PgnNodeData {
  final String san;
  List<String>? startingComments;
  List<String>? comments;
  List<int>? nags;
  PgnNodeData(
      {required this.san, this.startingComments, this.comments, this.nags});
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
  List<String>? comments;
  Node<T> moves;

  Game({required this.headers, required this.moves});
}

class ParserFrame {
  Node<PgnNodeData> parent;
  bool root;
  ChildNode<PgnNodeData>? node;
  List<String>? startingComments;

  ParserFrame({required this.parent, required this.root});
}

enum ParserState { bom, pre, headers, moves, comment }

enum PgnState { pre, sidelines, end }

class PgnFrame {
  PgnState state;
  int ply;
  ChildNode<PgnNodeData> node;
  Iterator<ChildNode<PgnNodeData>> sidelines;
  bool startsVariation;
  bool inVariation;

  PgnFrame(
      {required this.state,
      required this.ply,
      required this.node,
      required this.sidelines,
      required this.startsVariation,
      required this.inVariation});
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

Game<T> defaultGame<T>([initHeaders = defaultHeaders]) {
  return Game<T>(headers: initHeaders(), moves: Node());
}

var escapeHeader = (String value) =>
    value.replaceAll(RegExp(r'\\'), "\\\\").replaceAll(RegExp(r'"'), '\\"');
var safeComment = (String value) => value.replaceAll(RegExp(r'\}'), '');

int getPlyFromSetup(String fen) {
  try {
    var setup = Setup.parseFen(fen);
    return (setup.fullmoves - 1) * 2 + (setup.turn == Side.white ? 0 : 1);
  } catch (e) {
    return 0;
  }
}

String makeOutcome(Outcome? outcome) {
  if (outcome == null) {
    return '*';
  } else if (outcome.winner == Side.white) {
    return '1-0';
  } else if (outcome.winner == Side.black) {
    return '0-1';
  } else {
    return '1/2-1/2';
  }
}

Outcome? parseOutcome(String? outcome) {
  if (outcome == '1/2-1/2') {
    return Outcome.draw;
  } else if (outcome == '1-0') {
    return Outcome.whiteWins;
  } else if (outcome == '0-1') {
    return Outcome.blackWins;
  } else {
    return null;
  }
}

String makePgn(Game<PgnNodeData> game) {
  var builder = [], token = [];

  if (game.headers.isNotEmpty) {
    game.headers.forEach((key, value) {
      builder.add('[$key "${escapeHeader(value)}"]\n');
    });
    builder.add('\n');
  }

  if (game.comments != null) {
    for (var comment in game.comments!) {
      builder.add('{ ${safeComment(comment)} }');
    }
  }

  var fen = game.headers['FEN'];
  var initialPly = fen != null ? getPlyFromSetup(fen) : 0;

  List<PgnFrame> stack = [];

  if (game.moves.children.isNotEmpty) {
    var variations = game.moves.children.iterator;
    variations.moveNext();
    stack.add(PgnFrame(
        state: PgnState.pre,
        ply: initialPly,
        node: variations.current,
        sidelines: variations,
        startsVariation: false,
        inVariation: false));
  }

  var forceMoveNumber = true;
  while (stack.isNotEmpty) {
    var frame = stack[stack.length - 1];

    if (frame.inVariation) {
      token.add(')');
      frame.inVariation = false;
      forceMoveNumber = true;
    }

    switch (frame.state) {
      case PgnState.pre:
        {
          if (frame.node.data.startingComments != null) {
            for (var comment in frame.node.data.startingComments!) {
              token.add('{ ${safeComment(comment)} }');
            }
            forceMoveNumber = true;
          }
          if (forceMoveNumber || frame.ply % 2 == 0) {
            token.add(
                '${(frame.ply / 2).floor() + 1}${frame.ply % 2 == 1 ? "..." : "."}');
            forceMoveNumber = false;
          }
          token.add(frame.node.data.san);
          if (frame.node.data.nags != null) {
            for (var nag in frame.node.data.nags!) {
              token.add('\$$nag');
            }
            forceMoveNumber = true;
          }
          if (frame.node.data.comments != null) {
            for (var comment in frame.node.data.comments!) {
              token.add('{ ${safeComment(comment)} }');
            }
          }
          frame.state = PgnState.sidelines;
          continue;
        }

      case PgnState.sidelines:
        {
          var child = frame.sidelines.moveNext();
          if (child) {
            token.add('(');
            forceMoveNumber = true;
            stack.add(PgnFrame(
                state: PgnState.pre,
                ply: frame.ply,
                node: frame.sidelines.current,
                sidelines:
                    <ChildNode<PgnNodeData>>[].iterator, // empty iterator
                startsVariation: true,
                inVariation: false));
            frame.inVariation = true;
          } else {
            if (frame.node.children.isNotEmpty) {
              var variations = frame.node.children.iterator;
              variations.moveNext();
              stack.add(PgnFrame(
                  state: PgnState.pre,
                  ply: frame.ply + 1,
                  node: variations.current,
                  sidelines: variations,
                  startsVariation: false,
                  inVariation: false));
            }
            frame.state = PgnState.end;
          }
          break;
        }

      case PgnState.end:
        {
          stack.removeLast();
        }
    }
  }
  token.add(makeOutcome(parseOutcome(game.headers['Result'])));
  builder.add('${token.join(" ")}\n');
  return builder.join('');
}
