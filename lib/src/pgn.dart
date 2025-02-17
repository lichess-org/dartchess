import 'dart:math' as math;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'package:meta/meta.dart';
import './setup.dart';
import './models.dart';
import './position.dart';

typedef PgnHeaders = Map<String, String>;

/// A Portable Game Notation (PGN) representation.
///
/// A PGN game is composed of [PgnHeaders] and moves represented by a [PgnNode] tree.
///
/// ## Parser
///
/// This class provide 2 parsers: `parsePgn` to create a single [PgnGame] and
/// `parseMultiGamePgn` that can handle a string containing multiple games.
///
/// ```dart
/// const pgn = '1. d4 d5 *';
/// final game = PgnGame.parsePgn(pgn);
/// Position position = PgnGame.startingPosition(game.headers);
/// for (final node in game.moves.mainline()) {
///   final move = position.parseSan(node.san);
///   if (move == null) break; // Illegal move
///   position = position.play(move);
/// }
/// ```
///
/// ## Augmenting game tree
///
/// You can use [PgnNode.transform] to augment all nodes in the game tree with user data.
///
/// It allows you to provide context. You update the context inside the
/// callback. Context object itself should be immutable to prevent any unwanted mutation.
/// In the example below, the current [Position] `pos` is provided as context.
///
/// ```dart
/// class PgnNodeWithFen extends PgnNodeData {
///   final String fen;
///   const PgnNodeWithFen(
///       {required this.fen,
///       required super.san,
///       super.startingComments,
///       super.comments,
///       super.nags});
///
///    // Override == and hashCode
///    // ...
/// }
///
/// final game = PgnGame.parsePgn('1. e4 e5 *');
/// final pos = PgnGame.startingPosition(game.headers);
/// final PgnNode<NodeWithFen> res = game.moves.transform<NodeWithFen, Position>(pos,
///   (pos, data, _) {
///     final move = pos.parseSan(data.san);
///     if (move != null) {
///       final newPos = pos.play(move);
///       return (
///           newPos, NodeWithFen(fen: newPos.fen, san: data.san, comments: data.comments, nags: data.nags));
///     }
///     return null;
///   },
/// );
/// ```
class PgnGame<T extends PgnNodeData> {
  /// Constructs a new [PgnGame].
  PgnGame({required this.headers, required this.moves, required this.comments});

  /// Headers of the game.
  final PgnHeaders headers;

  /// Initial comments of the game.
  final List<String> comments;

  /// Parent node containing the game.
  final PgnNode<T> moves;

  /// Create default headers of a PGN.
  static PgnHeaders defaultHeaders() => {
        'Event': '?',
        'Site': '?',
        'Date': '????.??.??',
        'Round': '?',
        'White': '?',
        'Black': '?',
        'Result': '*'
      };

  /// Create empty headers of a PGN.
  static PgnHeaders emptyHeaders() => <String, String>{};

  /// Parse a PGN string and return a [PgnGame].
  ///
  /// Provide a optional function [initHeaders] to create different headers other than the default.
  ///
  /// The parser will interpret any input as a PGN, creating a tree of
  /// syntactically valid (but not necessarily legal) moves, skipping any invalid
  /// tokens.
  static PgnGame<PgnNodeData> parsePgn(String pgn,
      {PgnHeaders Function() initHeaders = defaultHeaders}) {
    final List<PgnGame<PgnNodeData>> games = [];
    _PgnParser((PgnGame<PgnNodeData> game) {
      games.add(game);
    }, initHeaders)
        .parse(pgn);

    if (games.isEmpty) {
      return PgnGame(
          headers: initHeaders(), moves: PgnNode(), comments: const []);
    }
    return games[0];
  }

  /// Parse a multi game PGN string.
  ///
  /// Returns a list of [PgnGame].
  /// Provide a optional function [initHeaders] to create different headers other than the default
  ///
  /// The parser will interpret any input as a PGN, creating a tree of
  /// syntactically valid (but not necessarily legal) moves, skipping any invalid
  /// tokens.
  static List<PgnGame<PgnNodeData>> parseMultiGamePgn(String pgn,
      {PgnHeaders Function() initHeaders = defaultHeaders}) {
    final multiGamePgnSplit = RegExp(r'\n\s+(?=\[)');
    final List<PgnGame<PgnNodeData>> games = [];
    final pgnGames = pgn.split(multiGamePgnSplit);
    for (final pgnGame in pgnGames) {
      final List<PgnGame<PgnNodeData>> parsedGames = [];
      _PgnParser((PgnGame<PgnNodeData> game) {
        parsedGames.add(game);
      }, initHeaders)
          .parse(pgnGame);
      if (parsedGames.isNotEmpty) {
        games.add(parsedGames[0]);
      }
    }
    return games;
  }

  /// Create a [Position] for a Variant from the headers.
  ///
  /// Headers can include an optional 'Variant' and 'Fen' key.
  ///
  /// Throws a [PositionSetupException] if it does not meet basic validity requirements.
  static Position startingPosition(PgnHeaders headers,
      {bool? ignoreImpossibleCheck}) {
    final rule = Rule.fromPgn(headers['Variant']);
    if (rule == null) throw PositionSetupException.variant;
    if (!headers.containsKey('FEN')) {
      return Position.initialPosition(rule);
    }
    final fen = headers['FEN']!;
    try {
      return Position.setupPosition(rule, Setup.parseFen(fen),
          ignoreImpossibleCheck: ignoreImpossibleCheck);
    } catch (err) {
      rethrow;
    }
  }

  /// Make a PGN String from [PgnGame].
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
      final variations = moves.children.iterator;
      variations.moveNext();
      stack.add(_PgnFrame(
          state: _PgnState.pre,
          ply: initialPly,
          node: variations.current,
          sidelines: variations,
          startsVariation: false,
          inVariation: false));
    }

    bool forceMoveNumber = true;
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
    token.write(Outcome.toPgnString(Outcome.fromPgn(headers['Result'])));
    builder.writeln(token.toString());
    return builder.toString();
  }
}

/// PGN data for a [PgnNode].
class PgnNodeData {
  /// Constructs a new [PgnNodeData].
  PgnNodeData(
      {required this.san, this.startingComments, this.comments, this.nags});

  /// SAN representation of the move.
  final String san;

  /// PGN comments before the move.
  List<String>? startingComments;

  /// PGN comments after the move.
  List<String>? comments;

  /// Numeric Annotation Glyphs for the move.
  List<int>? nags;
}

/// Parent node containing a list of child nodes (does not contain any data itself).
class PgnNode<T extends PgnNodeData> {
  final List<PgnChildNode<T>> children = [];

  /// Implements an [Iterable] to iterate the mainline.
  Iterable<T> mainline() sync* {
    var node = this;
    while (node.children.isNotEmpty) {
      final child = node.children[0];
      yield child.data;
      node = child;
    }
  }

  /// Transform this node into a [PgnNode<U>] tree.
  ///
  /// The callback function [f] is called for each node in the tree. If the
  /// callback returns null, the node is not added to the result tree.
  /// The callback should return a tuple of the updated context and node data.
  PgnNode<U> transform<U extends PgnNodeData, C>(
      C context, (C, U)? Function(C context, T data, int childIndex) f) {
    final root = PgnNode<U>();
    final stack = [(before: this, after: root, context: context)];

    while (stack.isNotEmpty) {
      final frame = stack.removeLast();
      for (int childIdx = 0;
          childIdx < frame.before.children.length;
          childIdx++) {
        C ctx = frame.context;
        final childBefore = frame.before.children[childIdx];
        final transformData = f(ctx, childBefore.data, childIdx);
        if (transformData != null) {
          final (newCtx, data) = transformData;
          ctx = newCtx;
          final childAfter = PgnChildNode(data);
          frame.after.children.add(childAfter);
          stack.add((before: childBefore, after: childAfter, context: ctx));
        }
      }
    }
    return root;
  }
}

/// PGN child Node.
///
/// This class has a mutable `data` field.
class PgnChildNode<T extends PgnNodeData> extends PgnNode<T> {
  PgnChildNode(this.data);

  /// PGN Data.
  T data;
}

/// Represents the color of a PGN comment.
///
/// Can be green, red, yellow, and blue.
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

/// A PGN comment shape.
///
/// Example of a comment shape "%cal Ra1b2" with color: Red from:a1 to:b2.
@immutable
class PgnCommentShape {
  const PgnCommentShape(
      {required this.color, required this.from, required this.to});

  final CommentShapeColor color;
  final Square from;
  final Square to;

  @override
  String toString() {
    return to == from
        ? '${color.string[0]}${to.name}'
        : '${color.string[0]}${from.name}${to.name}';
  }

  /// Parse the PGN for any comment or return null.
  static PgnCommentShape? fromPgn(String str) {
    final color = CommentShapeColor.parseShapeColor(str.substring(0, 1));
    final from = Square.parse(str.substring(1, 3));
    if (color == null || from == null) return null;
    if (str.length == 3) {
      return PgnCommentShape(color: color, from: from, to: from);
    }
    final to = Square.parse(str.substring(3, 5));
    if (str.length == 5 && to != null) {
      return PgnCommentShape(color: color, from: from, to: to);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PgnCommentShape &&
          color == other.color &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => Object.hash(color, from, to);
}

/// Represents the type of [PgnEvaluation].
enum EvalType { pawns, mate }

/// Pgn representation of a move evaluation.
///
/// A [PgnEvaluation] can be created used `.pawns` or `.mate` contructor.
@immutable
class PgnEvaluation {
  /// Constructor to create a [PgnEvaluation] of type pawns.
  const PgnEvaluation.pawns(
      {required this.pawns,
      this.depth,
      this.mate,
      this.evalType = EvalType.pawns});

  /// Constructor to create a [PgnEvaluation] of type mate.
  const PgnEvaluation.mate(
      {required this.mate,
      this.depth,
      this.pawns,
      this.evalType = EvalType.mate});

  final double? pawns;
  final int? mate;
  final int? depth;
  final EvalType evalType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
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

/// A PGN comment.
@immutable
class PgnComment {
  const PgnComment(
      {this.text,
      this.shapes = const IListConst([]),
      this.clock,
      this.emt,
      this.eval})
      : assert(text == null || text != '');

  /// Comment string.
  final String? text;

  /// List of comment shapes.
  final IList<PgnCommentShape> shapes;

  /// Player's remaining time.
  final Duration? clock;

  /// Player's elapsed move time.
  final Duration? emt;

  /// Move evaluation.
  final PgnEvaluation? eval;

  /// Parses a PGN comment string to a [PgnComment].
  factory PgnComment.fromPgn(String comment) {
    Duration? emt;
    Duration? clock;
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
      final secondsValue = double.parse(seconds!);
      final duration = Duration(
          hours: int.parse(hours!),
          minutes: int.parse(minutes!),
          seconds: secondsValue.truncate(),
          milliseconds:
              ((secondsValue - secondsValue.truncate()) * 1000).round());
      if (annotation == 'emt') {
        emt = duration;
      } else if (annotation == 'clk') {
        clock = duration;
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
        text: text.isNotEmpty ? text : null,
        shapes: IList(shapes),
        emt: emt,
        clock: clock,
        eval: eval);
  }

  /// Make a PGN string from this comment.
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

  @override
  String toString() =>
      'PgnComment(text: $text, shapes: $shapes, emt: $emt, clock: $clock, eval: $eval)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PgnComment &&
            text == other.text &&
            shapes == other.shapes &&
            clock == other.clock &&
            emt == other.emt &&
            eval == other.eval;
  }

  @override
  int get hashCode => Object.hash(text, shapes, clock, emt, eval);
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
    value.replaceAll(RegExp(r'\\'), '\\\\').replaceAll(RegExp('"'), '\\"');

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

/// A class to read a string and create a [PgnGame]
class _PgnParser {
  List<String> _lineBuf = [];
  late bool _found;
  late _ParserState _state = _ParserState.pre;
  late PgnHeaders _gameHeaders;
  late List<String> _gameComments;
  late PgnNode<PgnNodeData> _gameMoves;
  late List<_ParserFrame> _stack;
  late List<String> _commentBuf;

  /// Function to which the parsed game is passed to
  final void Function(PgnGame<PgnNodeData>) emitGame;

  /// Function to create the headers
  final PgnHeaders Function() initHeaders;

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

  void _emit() {
    if (_state == _ParserState.comment) {
      _handleComment();
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
    var idx = 0;
    for (;;) {
      final nlIdx = data.indexOf('\n', idx);
      if (nlIdx == -1) {
        break;
      }
      final crIdx = nlIdx > idx && data[nlIdx - 1] == '\r' ? nlIdx - 1 : nlIdx;
      _lineBuf.add(data.substring(idx, crIdx));
      idx = nlIdx + 1;
      _handleLine();
    }
    _lineBuf.add(data.substring(idx));

    _handleLine();
    _emit();
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
              if (_isWhitespace(line) || _isCommentLine(line)) return;
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
                  _state = _ParserState.comment;
                  if (openIndex < line.length) {
                    final beginIndex =
                        line[openIndex] == ' ' ? openIndex + 1 : openIndex;
                    line = line.substring(beginIndex);
                  } else if (openIndex == line.length) {
                    return;
                  }
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
      frame.node!.data.nags ??= [];
      frame.node!.data.nags?.add(nag);
    }
  }

  void _handleComment() {
    final frame = _stack[_stack.length - 1];
    final comment = _commentBuf.join('\n');
    _commentBuf = [];
    if (frame.node != null) {
      frame.node!.data.comments ??= [];
      frame.node!.data.comments?.add(comment);
    } else if (frame.root) {
      _gameComments.add(comment);
    } else {
      frame.startingComments ??= [];
      frame.startingComments!.add(comment);
    }
  }
}

/// Make the clock to string from seconds
String _makeClk(Duration duration) {
  final seconds = duration.inMilliseconds / 1000;
  final positiveSecs = math.max(0, seconds);
  final hours = (positiveSecs / 3600).floor();
  final minutes = ((positiveSecs % 3600) / 60).floor();
  final maxSec = (positiveSecs % 3600) % 60;
  final intVal = maxSec.toInt();
  final frac = (maxSec - intVal) // get the fraction part of seconds
      .toStringAsFixed(3)
      .replaceAll(RegExp(r'\.?0+$'), '')
      .substring(1);
  final dec =
      intVal.toString().padLeft(2, '0'); // get the decimal part of seconds
  return '$hours:${minutes.toString().padLeft(2, "0")}:$dec$frac';
}
