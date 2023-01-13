import 'dart:math';

import 'package:meta/meta.dart';
import './setup.dart';
import './models.dart';
import './position.dart';
import './utils.dart';

typedef Headers = Map<String, String>;

/// A Node containing PGN data for a move
@immutable
class PgnNodeData {
  /// SAN representation of the move
  final String san;

  /// Starting comments of the node
  final List<String>? startingComments;

  /// Comments about the node
  final List<String>? comments;

  /// Numeric Annotation Glyphs for the move
  final List<int>? nags;

  /// Constructor for the class
  const PgnNodeData(
      {required this.san, this.startingComments, this.comments, this.nags});

  @override
  bool operator ==(Object other) =>
      other is PgnNodeData &&
      san == other.san &&
      startingComments == other.startingComments &&
      comments == other.comments &&
      nags == other.nags;

  @override
  int get hashCode => Object.hash(san, startingComments, comments, nags);

  /// Return a new PgnNodeData by adding a [comment] to the current object
  PgnNodeData copyWithComment(String comment) {
    final List<String> newComment = [];
    if (comments != null) newComment.addAll(comments!);
    newComment.add(comment);
    return PgnNodeData(
        san: san,
        startingComments: startingComments,
        comments: newComment,
        nags: nags);
  }

  /// Return a new PgnNodeData by adding a [nag] to the current object
  PgnNodeData copyWithNags(int nag) {
    final List<int> newNags = [];
    if (comments != null) newNags.addAll(nags!);
    newNags.add(nag);
    return PgnNodeData(
        san: san,
        startingComments: startingComments,
        comments: comments,
        nags: newNags);
  }
}

class _TransformFrame<T, U, C> {
  final PgnNode<T> before;
  final PgnNode<U> after;
  final C ctx;

  _TransformFrame(this.before, this.after, this.ctx);
}

/// Parent Node containing list of child nodes (Does not contain any data)
class PgnNode<T> {
  final List<PgnChildNode<T>> children = [];

  /// Implements a Iterable for the node and its children
  ///
  /// Used for only iterating the mainline
  Iterable<T> mainline() sync* {
    var node = this;
    while (node.children.isNotEmpty) {
      final child = node.children[0];
      yield child.data;
      node = child;
    }
  }

  /// Function to walk through each node and transform Node<V> tree into Node<U> tree
  PgnNode<U> transform<U, C>(C ctx, U? Function(C, T, int) f) {
    final root = PgnNode<U>();
    final stack = [_TransformFrame<T, U, C>(this, root, ctx)];

    while (stack.isNotEmpty) {
      final frame = stack.removeLast();
      for (var childIdx = 0;
          childIdx < frame.before.children.length;
          childIdx++) {
        final childBefore = frame.before.children[childIdx];
        final data = f(ctx, childBefore.data, childIdx);
        if (data != null) {
          final childAfter = PgnChildNode(data);
          frame.after.children.add(childAfter);
          stack.add(_TransformFrame(childBefore, childAfter, ctx));
        }
      }
    }
    return root;
  }
}

/// Child Node with PGN data
class PgnChildNode<T> extends PgnNode<T> {
  /// PGN Data
  T data;
  PgnChildNode(this.data);
}

/// A game represented by headers and moves
///
/// Used to convert a chess game from or to a PGN
@immutable
class PgnGame<T> {
  /// Headers of the game
  final Headers headers;

  /// Inital comments of the game
  final List<String> comments;

  /// Parant node containing the game
  final PgnNode<T> moves;

  /// Constant contructor of the class.
  ///
  /// Returns a new immutable Game
  const PgnGame(
      {required this.headers, required this.moves, required this.comments});

  /// Default function headers of a PGN
  static Headers defaultHeaders() => {
        'Event': '?',
        'Site': '?',
        'Date': '????.??.??',
        'Round': '?',
        'White': '?',
        'Black': '?',
        'Result': '*'
      };

  /// Create empty headers of a PGN
  static Headers emptyHeaders() => <String, String>{};

  /// Parse a pgn and return a [PgnGame]
  ///
  /// Optinally provide a Function [initHeaders] to change the default headers
  /// Throws [PgnError] if String cannot be parsed
  static PgnGame<PgnNodeData> parsePgn(String pgn,
      {Headers Function() initHeaders = defaultHeaders}) {
    final List<PgnGame<PgnNodeData>> games = [];
    _PgnParser((PgnGame<PgnNodeData> game, {PgnError? error}) {
      if (error != null) throw error;
      games.add(game);
    }, initHeaders)
        .parse(pgn);
    return games[0];
  }

  /// Create a PGN String from [PgnGame]
  String makePgn() {
    final builder = StringBuffer();
    final token = StringBuffer();

    if (headers.isNotEmpty) {
      headers.forEach((key, value) {
        builder.writeln('[$key "${_escapeHeader(value)}"]');
      });
      builder.write('\n');
    }

    for (final comment in comments) {
      builder.writeln('{ ${_safeComment(comment)} }');
    }

    final fen = headers['FEN'];
    final initialPly = fen != null ? _getPlyFromSetup(fen) : 0;

    final List<_PgnFrame> stack = [];

    if (moves.children.isNotEmpty) {
      final variations =
          moves.children.iterator as Iterator<PgnChildNode<PgnNodeData>>;
      variations.moveNext();
      stack.add(_PgnFrame(
          state: _PgnState.pre,
          ply: initialPly,
          node: variations.current,
          sidelines: variations,
          startsVariation: false,
          inVariation: false));
    }

    var forceMoveNumber = true;
    while (stack.isNotEmpty) {
      final frame = stack[stack.length - 1];

      if (frame.inVariation) {
        token.write(') ');
        frame.inVariation = false;
        forceMoveNumber = true;
      }

      switch (frame.state) {
        case _PgnState.pre:
          {
            if (frame.node.data.startingComments != null) {
              for (final comment in frame.node.data.startingComments!) {
                token.write('{ ${_safeComment(comment)} } ');
              }
              forceMoveNumber = true;
            }
            if (forceMoveNumber || frame.ply.isEven) {
              token.write(
                  '${(frame.ply / 2).floor() + 1}${frame.ply.isOdd ? "..." : "."} ');
              forceMoveNumber = false;
            }
            token.write('${frame.node.data.san} ');
            if (frame.node.data.nags != null) {
              for (final nag in frame.node.data.nags!) {
                token.write('\$$nag ');
              }
              forceMoveNumber = true;
            }
            if (frame.node.data.comments != null) {
              for (final comment in frame.node.data.comments!) {
                token.write('{ ${_safeComment(comment)} } ');
              }
            }
            frame.state = _PgnState.sidelines;
            continue;
          }

        case _PgnState.sidelines:
          {
            final child = frame.sidelines.moveNext();
            if (child) {
              token.write('( ');
              forceMoveNumber = true;
              stack.add(_PgnFrame(
                  state: _PgnState.pre,
                  ply: frame.ply,
                  node: frame.sidelines.current,
                  sidelines:
                      <PgnChildNode<PgnNodeData>>[].iterator, // empty iterator
                  startsVariation: true,
                  inVariation: false));
              frame.inVariation = true;
            } else {
              if (frame.node.children.isNotEmpty) {
                final variations = frame.node.children.iterator;
                variations.moveNext();
                stack.add(_PgnFrame(
                    state: _PgnState.pre,
                    ply: frame.ply + 1,
                    node: variations.current,
                    sidelines: variations,
                    startsVariation: false,
                    inVariation: false));
              }
              frame.state = _PgnState.end;
            }
            break;
          }

        case _PgnState.end:
          {
            stack.removeLast();
          }
      }
    }
    token.write(Outcome.toPgnString(Outcome.fromPgn(headers["Result"])));
    builder.writeln(token.toString());
    return builder.toString();
  }
}

/// A frame used for parsing a line
class _ParserFrame {
  PgnNode<PgnNodeData> parent;
  bool root;
  PgnChildNode<PgnNodeData>? node;
  List<String>? startingComments;

  _ParserFrame({required this.parent, required this.root});
}

enum _ParserState { bom, pre, headers, moves, comment }

enum _PgnState { pre, sidelines, end }

/// A frame used for creating PGN
class _PgnFrame {
  _PgnState state;
  int ply;
  PgnChildNode<PgnNodeData> node;
  Iterator<PgnChildNode<PgnNodeData>> sidelines;
  bool startsVariation;
  bool inVariation;

  _PgnFrame(
      {required this.state,
      required this.ply,
      required this.node,
      required this.sidelines,
      required this.startsVariation,
      required this.inVariation});
}

/// Remove escape sequence from the string
String _escapeHeader(String value) =>
    value.replaceAll(RegExp(r'\\'), "\\\\").replaceAll(RegExp('"'), '\\"');

/// Remove '}' from the comment string
String _safeComment(String value) => value.replaceAll(RegExp(r'\}'), '');

/// Return ply from a fen if fen is valid else return 0
int _getPlyFromSetup(String fen) {
  try {
    final setup = Setup.parseFen(fen);
    return (setup.fullmoves - 1) * 2 + (setup.turn == Side.white ? 0 : 1);
  } catch (e) {
    return 0;
  }
}

const _bom = '\ufeff';

bool _isWhitespace(String line) => RegExp(r'^\s*$').hasMatch(line);

bool _isCommentLine(String line) => line.startsWith('%');

/// Exception when parsing a PGN
class PgnError implements Exception {
  final String message;
  PgnError(this.message);
}

/// A class to read a string and create a [PgnGame]
class _PgnParser {
  List<String> _lineBuf = [];
  late bool _found;
  late _ParserState _state = _ParserState.pre;
  late Headers _gameHeaders;
  late List<String> _gameComments;
  late PgnNode<PgnNodeData> _gameMoves;
  late List<_ParserFrame> _stack;
  late List<String> _commentBuf;

  /// Function to which the parsed game is passed to
  final void Function(PgnGame<PgnNodeData>, {PgnError? error}) emitGame;

  /// Function to create the headers
  final Headers Function() initHeaders;

  _PgnParser(this.emitGame, this.initHeaders) {
    _resetGame();
    _state = _ParserState.bom;
  }

  void _resetGame() {
    _found = false;
    _state = _ParserState.pre;
    _gameHeaders = initHeaders();
    _gameMoves = PgnNode();
    _gameComments = [];
    _commentBuf = [];
    _stack = [_ParserFrame(parent: _gameMoves, root: true)];
  }

  void _emit(Object? err) {
    if (_state == _ParserState.comment) {
      _handleComment();
    }
    if (err != null) {
      return emitGame(
          PgnGame(
              headers: _gameHeaders,
              moves: _gameMoves,
              comments: _gameComments),
          error: err as PgnError);
    }
    if (_found) {
      emitGame(
        PgnGame(
            headers: _gameHeaders, moves: _gameMoves, comments: _gameComments),
      );
    }
    _resetGame();
  }

  /// Parse the PGN string
  void parse(String data) {
    try {
      var idx = 0;
      for (;;) {
        final nlIdx = data.indexOf('\n', idx);
        if (nlIdx == -1) {
          break;
        }
        final crIdx =
            nlIdx > idx && data[nlIdx - 1] == '\r' ? nlIdx - 1 : nlIdx;
        _lineBuf.add(data.substring(idx, crIdx));
        idx = nlIdx + 1;
        _handleLine();
      }
      _lineBuf.add(data.substring(idx));

      _handleLine();
      _emit(null);
    } catch (err) {
      _emit(err);
    }
  }

  void _handleLine() {
    var freshLine = true;
    var line = _lineBuf.join();
    _lineBuf = [];
    continuedLine:
    for (;;) {
      switch (_state) {
        case _ParserState.bom:
          {
            if (line.startsWith(_bom)) {
              line = line.substring(_bom.length);
            }
            _state = _ParserState.pre;
            continue;
          }

        case _ParserState.pre:
          {
            if (_isWhitespace(line) || _isCommentLine(line)) return;
            _found = true;
            _state = _ParserState.headers;
            continue;
          }

        case _ParserState.headers:
          {
            if (_isCommentLine(line)) return;
            var moreHeaders = true;
            final headerReg = RegExp(
                r'^\s*\[([A-Za-z0-9][A-Za-z0-9_+#=:-]*)\s+"((?:[^"\\]|\\"|\\\\)*)"\]');
            while (moreHeaders) {
              moreHeaders = false;
              line = line.replaceFirstMapped(headerReg, (match) {
                if (match[1] != null && match[2] != null) {
                  _gameHeaders[match[1]!] =
                      match[2]!.replaceAll('\\"', '"').replaceAll('\\\\', '\\');
                  moreHeaders = true;
                  freshLine = false;
                }
                return '';
              });
            }
            if (_isWhitespace(line)) return;
            _state = _ParserState.moves;
            continue;
          }

        case _ParserState.moves:
          {
            if (freshLine) {
              if (_isCommentLine(line)) return;
              if (_isWhitespace(line)) return _emit(null);
            }
            final tokenRegex = RegExp(
                r'(?:[NBKRQ]?[a-h]?[1-8]?[-x]?[a-h][1-8](?:=?[nbrqkNBRQK])?|[pnbrqkPNBRQK]?@[a-h][1-8]|O-O-O|0-0-0|O-O|0-0)[+#]?|--|Z0|0000|@@@@|{|;|\$\d{1,4}|[?!]{1,2}|\(|\)|\*|1-0|0-1|1\/2-1\/2/');
            final matches = tokenRegex.allMatches(line);
            for (final match in matches) {
              final frame = _stack[_stack.length - 1];
              var token = match[0];
              if (token != null) {
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
                    _gameHeaders['Result'] = token;
                  }
                } else if (token == '(') {
                  _stack.add(_ParserFrame(parent: frame.parent, root: false));
                } else if (token == ')') {
                  if (_stack.length > 1) _stack.removeLast();
                } else if (token == '{') {
                  final openIndex = match.end;
                  final beginIndex =
                      line[openIndex] == ' ' ? openIndex + 1 : openIndex;
                  line = line.substring(beginIndex);
                  _state = _ParserState.comment;
                  continue continuedLine;
                } else {
                  if (token == 'Z0' || token == '0000' || token == '@@@@') {
                    token = '--';
                  } else if (token.startsWith('0')) {
                    token = token.replaceAll('0', 'O');
                  }
                  if (frame.node != null) {
                    frame.parent = frame.node!;
                  }
                  frame.node = PgnChildNode(PgnNodeData(
                      san: token, startingComments: frame.startingComments));
                  frame.startingComments = null;
                  frame.root = false;
                  frame.parent.children.add(frame.node!);
                }
              }
            }
            return;
          }

        case _ParserState.comment:
          {
            final closeIndex = line.indexOf('}');
            if (closeIndex == -1) {
              _commentBuf.add(line);
              return;
            } else {
              final endIndex = closeIndex > 0 && line[closeIndex - 1] == ' '
                  ? closeIndex - 1
                  : closeIndex;
              _commentBuf.add(line.substring(0, endIndex));
              _handleComment();
              line = line.substring(closeIndex);
              _state = _ParserState.moves;
              freshLine = false;
            }
          }
      }
    }
  }

  void _handleNag(int nag) {
    final frame = _stack[_stack.length - 1];
    if (frame.node != null) {
      frame.node!.data = frame.node!.data.copyWithNags(nag);
    }
  }

  void _handleComment() {
    final frame = _stack[_stack.length - 1];
    final comment = _commentBuf.join('\n');
    _commentBuf = [];
    if (frame.node != null) {
      frame.node!.data = frame.node!.data.copyWithComment(comment);
    } else if (frame.root) {
      _gameComments.add(comment);
    } else {
      frame.startingComments ??= [];
      frame.startingComments!.add(comment);
    }
  }
}

/// Function to parse a multi game PGN
///
/// Returns a list of games if multiple games found
/// Provide a optional function [initHeaders] to create different headers other than the default
/// Throws a [PgnError] if couldn't parse the pgn
List<PgnGame<PgnNodeData>> parseMultiGamePgn(String pgn,
    [Headers Function() initHeaders = PgnGame.defaultHeaders]) {
  final List<PgnGame<PgnNodeData>> games = [];
  _PgnParser((PgnGame<PgnNodeData> game, {PgnError? error}) {
    if (error != null) throw error;
    games.add(game);
  }, initHeaders)
      .parse(pgn);
  return games;
}

/// Represents the color of a comment
///
/// Can be green, red, yellow, and blue
enum CommentShapeColor {
  green,
  red,
  yellow,
  blue;

  String get string {
    switch (this) {
      case CommentShapeColor.green:
        return 'Green';
      case CommentShapeColor.red:
        return 'Red';
      case CommentShapeColor.yellow:
        return 'Yellow';
      case CommentShapeColor.blue:
        return 'Blue';
    }
  }

  static CommentShapeColor? parseShapeColor(String str) {
    switch (str) {
      case 'G':
        return CommentShapeColor.green;
      case 'R':
        return CommentShapeColor.red;
      case 'Y':
        return CommentShapeColor.yellow;
      case 'B':
        return CommentShapeColor.blue;
      default:
        return null;
    }
  }
}

/// A comment shape
///
/// Example of a comment shape "%cal Ra1b2" with color: Red from:a1 to:b2
@immutable
class PgnCommentShape {
  final CommentShapeColor color;
  final Square from;
  final Square to;

  const PgnCommentShape(
      {required this.color, required this.from, required this.to});

  @override
  String toString() {
    return to == from
        ? '${color.string[0]}${toAlgebraic(to)}'
        : '${color.string[0]}${toAlgebraic(from)}${toAlgebraic(to)}';
  }

  /// Parse the str for any comment or return null
  static PgnCommentShape? fromPgn(String str) {
    final color = CommentShapeColor.parseShapeColor(str.substring(0, 1));
    final from = parseSquare(str.substring(1, 3));
    if (color == null || from == null) return null;
    if (str.length == 3) {
      return PgnCommentShape(color: color, from: from, to: from);
    }
    final to = parseSquare(str.substring(3, 5));
    if (str.length == 5 && to != null) {
      return PgnCommentShape(color: color, from: from, to: to);
    }
    return null;
  }
}

/// Represents the type of [PgnEvaluation]
///
/// Can of of type pawns or mate
enum EvalType { pawns, mate }

/// A class containing an evaluation
/// A Evaluation object can be created used .pawns or .mate contructor
@immutable
class PgnEvaluation {
  final double? pawns;
  final int? mate;
  final int? depth;
  final EvalType evalType;

  /// Constructor to create Evaluation of type pawns
  const PgnEvaluation.pawns(
      {required this.pawns,
      this.depth,
      this.mate,
      this.evalType = EvalType.pawns});

  /// Constructor to create Evaluation of type mate
  const PgnEvaluation.mate(
      {required this.mate,
      this.depth,
      this.pawns,
      this.evalType = EvalType.mate});

  @override
  bool operator ==(Object other) =>
      other is PgnEvaluation &&
      pawns == other.pawns &&
      depth == other.depth &&
      mate == other.mate &&
      evalType == other.evalType;

  @override
  int get hashCode => Object.hash(pawns, depth, mate, evalType);

  bool isPawns() => evalType == EvalType.pawns;

  /// Create a PGN evaluation string
  String toPgn() {
    var str = '';
    if (isPawns()) {
      str = pawns!.toStringAsFixed(2);
    } else {
      str = '#$mate';
    }
    if (depth != null) str = '$str,$depth';
    return str;
  }
}

/// A comment class
@immutable
class PgnComment {
  /// Comment string
  final String? text;

  /// List of comment shapes
  final List<PgnCommentShape> shapes;
  final double? clock;
  final double? emt;
  final PgnEvaluation? eval;

  const PgnComment(
      {this.text, this.shapes = const [], this.clock, this.emt, this.eval});

  @override
  bool operator ==(Object other) {
    return other is PgnComment &&
        text == other.text &&
        clock == other.clock &&
        emt == other.emt &&
        eval == other.eval;
  }

  @override
  int get hashCode => Object.hash(text, shapes, clock, emt, eval);

  /// Create a PGN string from a comment
  String makeComment() {
    final List<String> builder = [];
    if (text != null) builder.add(text!);
    final circles = shapes
        .where((shape) => shape.to == shape.from)
        .map((shape) => shape.toString());
    if (circles.isNotEmpty) builder.add('[%csl ${circles.join(",")}]');
    final arrows = shapes
        .where((shape) => shape.to != shape.from)
        .map((shape) => shape.toString());
    if (arrows.isNotEmpty) builder.add('[%cal ${arrows.join(",")}]');
    if (eval != null) builder.add('[%eval ${eval!.toPgn()}]');
    if (emt != null) builder.add('[%emt ${_makeClk(emt!)}]');
    if (clock != null) builder.add('[%clk ${_makeClk(clock!)}]');
    return builder.join(' ');
  }

  /// Parse the comment from a string
  factory PgnComment.fromPgn(String comment) {
    double? emt;
    double? clock;
    final List<PgnCommentShape> shapes = [];
    PgnEvaluation? eval;
    final text = comment.replaceAllMapped(
        RegExp(
            r'\s?\[%(emt|clk)\s(\d{1,5}):(\d{1,2}):(\d{1,2}(?:\.\d{0,3})?)\]\s?'),
        (match) {
      final annotation = match.group(1);
      final hours = match.group(2);
      final minutes = match.group(3);
      final seconds = match.group(4);
      final value = double.parse(hours!) * 3600 +
          int.parse(minutes!) * 60 +
          double.parse(seconds!);
      if (annotation == 'emt') {
        emt = value;
      } else if (annotation == 'clk') {
        clock = value;
      }
      return '  ';
    }).replaceAllMapped(
        RegExp(
            r'\s?\[%(?:csl|cal)\s([RGYB][a-h][1-8](?:[a-h][1-8])?(?:,[RGYB][a-h][1-8](?:[a-h][1-8])?)*)\]\s?'),
        (match) {
      final arrows = match.group(1);
      if (arrows != null) {
        for (final arrow in arrows.split(',')) {
          final shape = PgnCommentShape.fromPgn(arrow);
          if (shape != null) shapes.add(shape);
        }
      }
      return '  ';
    }).replaceAllMapped(
        RegExp(
            r'\s?\[%eval\s(?:#([+-]?\d{1,5})|([+-]?(?:\d{1,5}|\d{0,5}\.\d{1,2})))(?:,(\d{1,5}))?\]\s?'),
        (match) {
      final mate = match.group(1);
      final pawns = match.group(2);
      final d = match.group(3);
      final depth = d != null ? int.parse(d) : null;
      eval = mate != null
          ? PgnEvaluation.mate(mate: int.parse(mate), depth: depth)
          : PgnEvaluation.pawns(
              pawns: pawns != null ? double.parse(pawns) : null, depth: depth);
      return '  ';
    }).trim();

    return PgnComment(
        text: text, shapes: shapes, emt: emt, clock: clock, eval: eval);
  }
}

/// Make the clock to string from seconds
String _makeClk(double seconds) {
  var maxSec = max(0, seconds);
  final hours = (maxSec / 3600).floor();
  final minutes = ((maxSec % 3600) / 60).floor();
  maxSec = (maxSec % 3600) % 60;
  final intVal = maxSec.toInt();
  final frac = (maxSec - intVal) // get the fraction part of seconds
      .toStringAsFixed(3)
      .replaceAll(RegExp(r'\.?0+$'), "")
      .substring(1);
  final dec =
      intVal.toString().padLeft(2, "0"); // get the decimal part of seconds
  return '$hours:${minutes.toString().padLeft(2, "0")}:$dec$frac';
}
