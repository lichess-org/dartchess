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

  PgnNodeData copyWith({String? comment, int? nag}) {
    List<String> newComments = [];
    List<int> newNags = [];
    if (comment != null) {
      if (comments != null) {
        comments!.add(comment);
        newComments = comments!.toList();
      } else {
        newComments.add(comment);
      }
    }
    if (nag != null) {
      if (nags != null) {
        nags!.add(nag);
        newNags = nags!.toList();
      } else {
        newNags.add(nag);
      }
    }
    return PgnNodeData(
        san: san,
        startingComments: startingComments ?? const [],
        comments: comment == null ? null : newComments,
        nags: nag == null ? null : newNags);
  }
}

/// Parent Node containing list of child nodes (Does not contain any data)
class PgnNode<T> {
  final List<PgnChildNode<T>> children =
      []; // this list is still growable so not completely immutable, and immutability is needed for parsing
  PgnNode();

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
}

/// Child Node contains data
class PgnChildNode<T> extends PgnNode<T> {
  T data;
  PgnChildNode(this.data);
}

/// A game represented by headers and moves
///
/// Used to convert into a PGN
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
  static Headers emptyHeaders() {
    return <String, String>{};
  }

  /// Parse a pgn and return a [PgnGame]
  ///
  /// Optinally provide a Function [initHeaders] to change the default headers
  static PgnGame<PgnNodeData> parsePgn(String pgn,
      [Headers Function() initHeaders = defaultHeaders]) {
    final List<PgnGame<PgnNodeData>> games = [];
    PgnParser((PgnGame<PgnNodeData> game, [Exception? err]) => games.add(game),
            initHeaders)
        .parse(pgn);
    return games[0];
  }

  /// Create a PGN String from [PgnGame]
  String makePgn() {
    final List<String> builder = [];
    final List<String> token = [];

    if (headers.isNotEmpty) {
      headers.forEach((key, value) {
        builder.add('[$key "${_escapeHeader(value)}"]\n');
      });
      builder.add('\n');
    }

    for (final comment in comments) {
      builder.add('{ ${_safeComment(comment)} }');
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
        token.add(')');
        frame.inVariation = false;
        forceMoveNumber = true;
      }

      switch (frame.state) {
        case _PgnState.pre:
          {
            if (frame.node.data.startingComments != null) {
              for (final comment in frame.node.data.startingComments!) {
                token.add('{ ${_safeComment(comment)} }');
              }
              forceMoveNumber = true;
            }
            if (forceMoveNumber || frame.ply.isEven) {
              token.add(
                  '${(frame.ply / 2).floor() + 1}${frame.ply.isOdd ? "..." : "."}');
              forceMoveNumber = false;
            }
            token.add(frame.node.data.san);
            if (frame.node.data.nags != null) {
              for (final nag in frame.node.data.nags!) {
                token.add('\$$nag');
              }
              forceMoveNumber = true;
            }
            if (frame.node.data.comments != null) {
              for (final comment in frame.node.data.comments!) {
                token.add('{ ${_safeComment(comment)} }');
              }
            }
            frame.state = _PgnState.sidelines;
            continue;
          }

        case _PgnState.sidelines:
          {
            final child = frame.sidelines.moveNext();
            if (child) {
              token.add('(');
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
    token.add(Outcome.toPgnString(Outcome.fromPgn(headers['Result'])));
    builder.add('${token.join(" ")}\n');
    return builder.join();
  }
}

class _TransformStack<T, U, C> {
  final PgnNode<T> before;
  final PgnNode<U> after;
  final C ctx;

  _TransformStack(this.before, this.after, this.ctx);
}

/// Function to walk thorugh each node and transform Node<T> tree into Node<U> tree
PgnNode<U> transform<T, U, C>(
    PgnNode<T> node, C ctx, U? Function(C, T, int) f) {
  final root = PgnNode<U>();
  final stack = [_TransformStack(node, root, ctx)];

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
        stack.add(_TransformStack(childBefore, childAfter, ctx));
      }
    }
  }
  return root;
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

const bom = '\ufeff';

bool isWhitespace(String line) => RegExp(r'^\s*$').hasMatch(line);

bool isCommentLine(String line) => line.startsWith('%');

class PgnError implements Exception {
  final String message;
  PgnError(this.message);
}

/// A class to read a string and create a [PgnGame]
class PgnParser {
  List<String> _lineBuf = [];
  late bool _found;
  late _ParserState _state = _ParserState.pre;
  late Headers _gameHeaders;
  late List<String> _gameComments;
  late PgnNode<PgnNodeData> _gameMoves;
  late List<_ParserFrame> _stack;
  late List<String> _commentBuf;

  /// Function to which the parse game is passed to
  final void Function(PgnGame<PgnNodeData>, [Exception?]) emitGame;

  /// Function to create the headers
  final Headers Function() initHeaders;

  PgnParser(this.emitGame, this.initHeaders) {
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

  void _emit(Exception? err) {
    if (_state == _ParserState.comment) {
      _handleComment();
    }
    if (err != null) {
      return emitGame(
          PgnGame(
              headers: _gameHeaders,
              moves: _gameMoves,
              comments: _gameComments),
          err);
    }
    if (_found) {
      emitGame(
          PgnGame(
              headers: _gameHeaders,
              moves: _gameMoves,
              comments: _gameComments),
          null);
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
      _emit(err as Exception);
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
            if (line.startsWith(bom)) {
              line = line.substring(bom.length);
            }
            _state = _ParserState.pre;
            continue;
          }

        case _ParserState.pre:
          {
            if (isWhitespace(line) || isCommentLine(line)) return;
            _found = true;
            _state = _ParserState.headers;
            continue;
          }

        case _ParserState.headers:
          {
            if (isCommentLine(line)) return;
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
            if (isWhitespace(line)) return;
            _state = _ParserState.moves;
            continue;
          }

        case _ParserState.moves:
          {
            if (freshLine) {
              if (isCommentLine(line)) return;
              if (isWhitespace(line)) return _emit(null);
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
      frame.node!.data = frame.node!.data.copyWith(nag: nag);
    }
  }

  void _handleComment() {
    final frame = _stack[_stack.length - 1];
    final comment = _commentBuf.join('\n');
    _commentBuf = [];
    if (frame.node != null) {
      frame.node!.data = frame.node!.data.copyWith(comment: comment);
    } else if (frame.root) {
      _gameComments.add(comment);
    } else {
      frame.startingComments ??= [];
      frame.startingComments!.add(comment);
    }
  }
}

/// Default function to parse a multi game PGN
///
/// Returns a list of games if multiple games found
/// Provide a optional function [initHeaders] to create different headers other than the default
List<PgnGame<PgnNodeData>> parseMultiGamePgn(String pgn,
    [Headers Function() initHeaders = PgnGame.defaultHeaders]) {
  final List<PgnGame<PgnNodeData>> games = [];
  PgnParser((PgnGame<PgnNodeData> game, [Exception? err]) => games.add(game),
          initHeaders)
      .parse(pgn);
  return games;
}

/// Create a [Position] from setup and variants
Position setupPosition(Variant rules, Setup setup,
    {bool? ignoreImpossibleCheck}) {
// TODO:missing horde, racingkings. Returns Chess for those variants
  switch (rules) {
    case Variant.chess:
      return Chess.fromSetup(setup,
          ignoreImpossibleCheck: ignoreImpossibleCheck);
    case Variant.antichess:
      return Antichess.fromSetup(setup,
          ignoreImpossibleCheck: ignoreImpossibleCheck);
    case Variant.atomic:
      return Atomic.fromSetup(setup,
          ignoreImpossibleCheck: ignoreImpossibleCheck);
    case Variant.kingofthehill:
      return KingOfTheHill.fromSetup(setup,
          ignoreImpossibleCheck: ignoreImpossibleCheck);
    case Variant.crazyhouse:
      return Crazyhouse.fromSetup(setup,
          ignoreImpossibleCheck: ignoreImpossibleCheck);
    case Variant.threecheck:
      return ThreeCheck.fromSetup(setup,
          ignoreImpossibleCheck: ignoreImpossibleCheck);
    default:
      return Chess.fromSetup(setup,
          ignoreImpossibleCheck: ignoreImpossibleCheck);
  }
}

/// Create a [Position] for a Variant from the headers
///
/// Headers must include a 'Variant' and 'Fen' key
Position startingPosition(Headers headers, {bool? ignoreImpossibleCheck}) {
  if (!headers.containsKey('Variant')) throw PgnError('ERR_HEADER_NO_VARIANT');
  final rules = Variant.fromPgn(headers['Variant']!);
  if (rules == null) throw PgnError('ERR_HEADER_INVALID_VARIANT');
  if (!headers.containsKey('FEN')) {
    return defualtPosition(rules);
  }
  final fen = headers['FEN']!;
  try {
    return setupPosition(rules, Setup.parseFen(fen),
        ignoreImpossibleCheck: ignoreImpossibleCheck);
  } catch (err) {
    rethrow;
  }
}

/// Returns the defualt [Position] for the [Variant]
Position defualtPosition(Variant variant) {
  switch (variant) {
    case Variant.chess:
      return Chess.initial;
    case Variant.antichess:
      return Antichess.initial;
    case Variant.atomic:
      return Atomic.initial;
    case Variant.kingofthehill:
      return KingOfTheHill.initial;
    case Variant.threecheck:
      return ThreeCheck.initial;
    case Variant.crazyhouse:
      return Crazyhouse.initial;
    case Variant.horde:
      return Chess.initial;
    default:
      return Chess.initial;
  }
}

/// Set the [Variant] and the 'FEN' for the headers
void setStartingPosition(Headers headers, Position pos) {
  final variant = pos.variant;
  if (variant != Variant.chess) {
    headers['Variant'] = variant.string!;
  } else {
    headers.remove('Variant');
  }

  final defaultFen = defualtPosition(pos.variant).fen;
  if (pos.fen != defaultFen) {
    headers['FEN'] = pos.fen;
  } else {
    headers.remove('FEN');
  }
}

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
/// Example of a comment shape "[%cal Ra1b2]" with color: Red from:a1 to:b2
@immutable
class CommentShape {
  final CommentShapeColor color;
  final Square from;
  final Square to;

  const CommentShape(
      {required this.color, required this.from, required this.to});

  @override
  String toString() {
    return to == from
        ? '${color.string[0]}${toAlgebraic(to)}'
        : '${color.string[0]}${toAlgebraic(from)}${toAlgebraic(to)}';
  }
}

enum EvalType { pawns, mate }

/// A class containing an evaluation
/// A Evaluation object can be created used .pawns or .mate contructor
@immutable
class Evaluation {
  final double? pawns;
  final int? mate;
  final int? depth;
  final EvalType evalType;

  /// Constructor to create Evaluation of type pawns
  const Evaluation.pawns(
      {required this.pawns,
      this.depth,
      this.mate,
      this.evalType = EvalType.pawns});

  /// Constructor to create Evaluation of type mate
  const Evaluation.mate(
      {required this.mate,
      this.depth,
      this.pawns,
      this.evalType = EvalType.mate});

  @override
  bool operator ==(Object other) =>
      other is Evaluation &&
      pawns == other.pawns &&
      depth == other.depth &&
      mate == other.mate;

  @override
  int get hashCode => evalType == EvalType.pawns
      ? Object.hash(pawns, depth)
      : Object.hash(mate, depth);

  bool isPawns() => evalType == EvalType.pawns;
}

/// A comment class
@immutable
class Comment {
  /// Comment string
  final String? text;

  /// List of comment shapes
  final List<CommentShape> shapes;
  final double? clock;
  final double? emt;
  final Evaluation? eval;

  const Comment(
      {this.text, this.shapes = const [], this.clock, this.emt, this.eval});

  @override
  bool operator ==(Object other) {
    return other is Comment &&
        text == other.text &&
        // shapes == other.shapes &&  List == operator doesnt compare each component of list
        // TODO: fix this
        // This function is only needed for testing.
        clock == other.clock &&
        emt == other.emt &&
        eval == other.eval;
  }

  @override
  int get hashCode => Object.hash(text, shapes, clock, emt, eval);
}

/// Make the clock to string from seconds
String makeClk(double seconds) {
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

/// Parse the str for any comment or return null
CommentShape? parseCommentShape(String str) {
  final color = CommentShapeColor.parseShapeColor(str.substring(0, 1));
  final from = parseSquare(str.substring(1, 3));
  if (color == null || from == null) return null;
  if (str.length == 3) return CommentShape(color: color, from: from, to: from);
  final to = parseSquare(str.substring(3, 5));
  if (str.length == 5 && to != null) {
    return CommentShape(color: color, from: from, to: to);
  }
  return null;
}

/// Create a evaluation string
String makeEval(Evaluation ev) {
  var str = '';
  if (ev.isPawns()) {
    str = ev.pawns!.toStringAsFixed(2);
  } else {
    str = '#${ev.mate}';
  }
  if (ev.depth != null) str = '$str,${ev.depth}';
  return str;
}

/// Create a string from a comment
String makeComment(Comment comment) {
  final List<String> builder = [];
  if (comment.text != null) builder.add(comment.text!);
  final circles = comment.shapes
      .where((shape) => shape.to == shape.from)
      .map((shape) => shape.toString());
  if (circles.isNotEmpty) builder.add('[%csl ${circles.join(",")}]');
  final arrows = comment.shapes
      .where((shape) => shape.to != shape.from)
      .map((shape) => shape.toString());
  if (arrows.isNotEmpty) builder.add('[%cal ${arrows.join(",")}]');
  if (comment.eval != null) builder.add('[%eval ${makeEval(comment.eval!)}]');
  if (comment.emt != null) builder.add('[%emt ${makeClk(comment.emt!)}]');
  if (comment.clock != null) builder.add('[%clk ${makeClk(comment.clock!)}]');
  return builder.join(' ');
}

/// Parse the comment from a string
Comment parseComment(String comment) {
  double? emt;
  double? clock;
  final List<CommentShape> shapes = [];
  Evaluation? eval;
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
        final shape = parseCommentShape(arrow);
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
        ? Evaluation.mate(mate: int.parse(mate), depth: depth)
        : Evaluation.pawns(
            pawns: pawns != null ? double.parse(pawns) : null, depth: depth);
    return '  ';
  }).trim();

  return Comment(
      text: text, shapes: shapes, emt: emt, clock: clock, eval: eval);
}
