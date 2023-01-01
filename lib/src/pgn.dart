import './setup.dart';
import './models.dart';
import './position.dart';

// TODO: ensure null checkes
class PgnNodeData {
  final String san;
  List<String>? startingComments;
  List<String>? comments;
  List<int>? nags;
  PgnNodeData(
      {required this.san, this.startingComments, this.comments, this.nags});
}

class Node<T> {
  List<Node<T>> children = [];
  T? data;
  Node(this.data);

  Iterable<T> mainline() sync* {
    var node = this;
    while (node.children.isNotEmpty) {
      var child = node.children[0];
      yield child.data!;
      node = child;
    }
  }
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
  Node<PgnNodeData>? node;
  List<String>? startingComments;

  ParserFrame({required this.parent, required this.root});
}

enum ParserState { bom, pre, headers, moves, comment }

enum PgnState { pre, sidelines, end }

class PgnFrame {
  PgnState state;
  int ply;
  Node<PgnNodeData> node;
  Iterator<Node<PgnNodeData>> sidelines;
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
  return Game<T>(headers: initHeaders(), moves: Node(null));
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
          if (frame.node.data!.startingComments != null) {
            for (var comment in frame.node.data!.startingComments!) {
              token.add('{ ${safeComment(comment)} }');
            }
            forceMoveNumber = true;
          }
          if (forceMoveNumber || frame.ply % 2 == 0) {
            token.add(
                '${(frame.ply / 2).floor() + 1}${frame.ply % 2 == 1 ? "..." : "."}');
            forceMoveNumber = false;
          }
          token.add(frame.node.data!.san);
          if (frame.node.data!.nags != null) {
            for (var nag in frame.node.data!.nags!) {
              token.add('\$$nag');
            }
            forceMoveNumber = true;
          }
          if (frame.node.data!.comments != null) {
            for (var comment in frame.node.data!.comments!) {
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
                sidelines: <Node<PgnNodeData>>[].iterator, // empty iterator
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

const BOM = '\ufeff';

var isWhitespace = (String line) => RegExp(r'^\s*$').hasMatch(line);

var isCommentLine = (String line) => line.startsWith('%');

class PgnError implements Exception {
  final String message;
  PgnError(this.message);
}

class PgnParser {
  List<String> _lineBuf = [];
  late int _budget;
  late bool _found;
  late ParserState _state = ParserState.pre;
  late Game<PgnNodeData> _game;
  late List<ParserFrame> _stack;
  late List<String> _commentBuf = [];
  int maxBudget;

  final void Function(Game<PgnNodeData>, [Error?]) emitGame;
  final Map<String, String> Function() initHeaders;

  PgnParser(this.emitGame, this.initHeaders, [this.maxBudget = 1000000]) {
    resetGame();
  }

  void resetGame() {
    _budget = maxBudget;
    _found = false;
    _state = ParserState.pre;
    _game = defaultGame(initHeaders);
    _stack = [ParserFrame(parent: _game.moves, root: true)];
    _commentBuf = [];
  }

  void _consumeBudget(int cost) {
    _budget -= cost;
    if (_budget < 0) {
      throw PgnError('ERR_PGN_BUDGET');
    }
  }

  void _emit(Error? err) {
    if (_state == ParserState.comment) {
      _handleComment();
    }
    if (err != null) {
      return emitGame(_game, err);
    }
    if (_found) {
      emitGame(_game, null);
    }
    resetGame();
  }

  void parse(String data, [bool? stream]) {
    if (_budget < 0) return;
    try {
      var idx = 0;
      for (;;) {
        final nlIdx = data.indexOf('\n', idx);
        if (nlIdx == -1) {
          break;
        }
        final crIdx =
            nlIdx > idx && data[nlIdx - 1] == '\r' ? nlIdx - 1 : nlIdx;
        _consumeBudget(nlIdx - idx);
        _lineBuf.add(data.substring(idx, crIdx));
        idx = nlIdx + 1;
        _handleLine();
      }
      _consumeBudget(data.length - idx);
      _lineBuf.add(data.substring(idx));

      if (stream == null) {
        _handleLine();
        _emit(null);
      }
    } catch (err) {
      _emit(err as Error);
    }
  }

  void _handleLine() {
    var freshLine = true;
    var line = _lineBuf.join('');
    _lineBuf = [];

    continuedLine:
    for (;;) {
      switch (_state) {
        case ParserState.bom:
          {
            if (line.startsWith(BOM)) {
              line = line.substring(BOM.length);
            }
            _state = ParserState.pre;
            continue;
          }

        case ParserState.pre:
          {
            if (isWhitespace(line) || isCommentLine(line)) return;
            _found = true;
            _state = ParserState.headers;
            continue;
          }

        case ParserState.headers:
          {
            if (isCommentLine(line)) return;
            var moreHeaders = true;
            var headerReg = RegExp(
                r'^\s*\[([A-Za-z0-9][A-Za-z0-9_+#=:-]*)\s+"((?:[^"\\]|\\"|\\\\)*)"\]');
            while (moreHeaders) {
              moreHeaders = false;
              line = line.replaceFirstMapped(headerReg, (match) {
                _consumeBudget(200);
                _game.headers[match[1]!] =
                    match[2]!.replaceAll(r'\\"', '"').replaceAll(r'\\\\', '\\');
                moreHeaders = true;
                freshLine = false;
                return '';
              });
            }
            if (isWhitespace(line)) return;
            _state = ParserState.moves;
            continue;
          }

        case ParserState.moves:
          {
            if (freshLine) {
              if (isCommentLine(line)) return;
              if (isWhitespace(line)) return _emit(null);
            }
            final tokenRegex = RegExp(
                r'(?:[NBKRQ]?[a-h]?[1-8]?[-x]?[a-h][1-8](?:=?[nbrqkNBRQK])?|[pnbrqkPNBRQK]?@[a-h][1-8]|O-O-O|0-0-0|O-O|0-0)[+#]?|--|Z0|0000|@@@@|{|;|\$\d{1,4}|[?!]{1,2}|\(|\)|\*|1-0|0-1|1\/2-1\/2/');
            var matches = tokenRegex.allMatches(line);

            for (var match in matches) {
              var frame = _stack[_stack.length - 1];
              var token = match[0]!;
              if (token == ';') {
                return;
              } else if (token.startsWith('\$')) {
                _handleNag(int.parse(token.substring(1)));
              } else if (token == '!') {
                _handleNag(1);
              } else if (token == '?') {
                _handleNag(2);
              } else if (token == '!!') {
                _handleNag(3);
              } else if (token == '??') {
                _handleNag(4);
              } else if (token == '!?') {
                _handleNag(5);
              } else if (token == '?!') {
                _handleNag(6);
              } else if (token == '1-0' ||
                  token == '0-1' ||
                  token == '1/2-1/2' ||
                  token == '*') {
                if (_stack.length == 1 && token != '*') {
                  _game.headers['Result'] = token;
                }
              } else if (token == '(') {
                _consumeBudget(100);
                _stack.add(ParserFrame(parent: frame.parent, root: false));
              } else if (token == ')') {
                if (_stack.length > 1) _stack.removeLast();
              } else if (token == '{') {
                var openIndex = match.end;
                var beginIndex =
                    line[openIndex] == ' ' ? openIndex + 1 : openIndex;
                line = line.substring(beginIndex);
                _state = ParserState.comment;
                continue continuedLine;
              } else {
                _consumeBudget(100);
                if (token == 'Z0' || token == '0000' || token == '@@@@') {
                  token = '--';
                } else if (token.startsWith('0')) {
                  token = token.replaceAll(r'0', 'O');
                }
                if (frame.node != null) frame.parent = frame.node!;
                frame.node = Node(PgnNodeData(
                    san: token, startingComments: frame.startingComments));
                frame.startingComments = null;
                frame.root = false;
                frame.parent.children.add(frame.node!);
              }
            }
            return;
          }

        case ParserState.comment:
          {
            var closeIndex = line.indexOf('}');
            if (closeIndex == -1) {
              _commentBuf.add(line);
              return;
            } else {
              var endIndex = closeIndex > 0 && line[closeIndex - 1] == ' '
                  ? closeIndex - 1
                  : closeIndex;
              _commentBuf.add(line.substring(0, endIndex));
              _handleComment();
              line = line.substring(closeIndex);
              _state = ParserState.moves;
              freshLine = false;
            }
          }
      }
    }
  }

  void _handleNag(int nag) {
    _consumeBudget(50);
    var frame = _stack[_stack.length - 1];
    if (frame.node != null) {
      frame.node!.data!.nags ??= [];
      frame.node!.data!.nags!.add(nag);
    }
  }

  void _handleComment() {
    _consumeBudget(100);
    var frame = _stack[_stack.length - 1];
    var comment = _commentBuf.join('\n');
    _commentBuf = [];
    if (frame.node != null) {
      frame.node!.data!.comments ??= [];
      frame.node!.data!.comments!.add(comment);
    } else if (frame.root) {
      _game.comments ??= [];
      _game.comments!.add(comment);
    } else {
      frame.startingComments ??= [];
      frame.startingComments!.add(comment);
    }
  }
}

var parsePgn = (String pgn,
    [Map<String, String> Function() initHeaders = defaultHeaders]) {
  List<Game<PgnNodeData>> games = [];
  PgnParser((Game<PgnNodeData> game, [Error? err]) => games.add(game),
          initHeaders)
      .parse(pgn);
  return games;
};
