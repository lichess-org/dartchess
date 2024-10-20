import 'package:meta/meta.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'dart:math' as math;
import './square_set.dart';
import './models.dart';
import './board.dart';

/// A not necessarily legal position.
@immutable
class Setup {
  /// Creates a new [Setup] with the provided values.
  const Setup({
    required this.board,
    this.pockets,
    required this.turn,
    required this.castlingRights,
    this.epSquare,
    required this.halfmoves,
    required this.fullmoves,
    this.remainingChecks,
  });

  /// Parses a Forsyth-Edwards-Notation string and returns a [Setup].
  ///
  /// The parser is relaxed:
  ///
  /// * Supports X-FEN and Shredder-FEN for castling right notation.
  /// * Accepts missing FEN fields (except the board) and fills them with
  ///   default values of `8/8/8/8/8/8/8/8 w - - 0 1`.
  /// * Accepts multiple spaces and underscores (`_`) as separators between
  ///   FEN fields.
  ///
  /// Throws a [FenException] if the provided FEN is not valid.
  factory Setup.parseFen(String fen) {
    final parts = fen.split(RegExp(r'[\s_]+'));
    if (parts.isEmpty) throw const FenException(IllegalFenCause.format);

    // board and pockets
    final boardPart = parts.removeAt(0);
    Pockets? pockets;
    Board board;
    if (boardPart.endsWith(']')) {
      final pocketStart = boardPart.indexOf('[');
      if (pocketStart == -1) {
        throw const FenException(IllegalFenCause.format);
      }
      board = Board.parseFen(boardPart.substring(0, pocketStart));
      pockets = _parsePockets(
          boardPart.substring(pocketStart + 1, boardPart.length - 1));
    } else {
      final pocketStart = _nthIndexOf(boardPart, '/', 7);
      if (pocketStart == -1) {
        board = Board.parseFen(boardPart);
      } else {
        board = Board.parseFen(boardPart.substring(0, pocketStart));
        pockets = _parsePockets(boardPart.substring(pocketStart + 1));
      }
    }

    // turn
    Side turn;
    if (parts.isEmpty) {
      turn = Side.white;
    } else {
      final turnPart = parts.removeAt(0);
      if (turnPart == 'w') {
        turn = Side.white;
      } else if (turnPart == 'b') {
        turn = Side.black;
      } else {
        throw const FenException(IllegalFenCause.turn);
      }
    }

    // Castling
    SquareSet castlingRights;
    if (parts.isEmpty) {
      castlingRights = SquareSet.empty;
    } else {
      final castlingPart = parts.removeAt(0);
      castlingRights = _parseCastlingFen(board, castlingPart);
    }

    // En passant square
    Square? epSquare;
    if (parts.isNotEmpty) {
      final epPart = parts.removeAt(0);
      if (epPart != '-') {
        epSquare = Square.parse(epPart);
        if (epSquare == null) {
          throw const FenException(IllegalFenCause.enPassant);
        }
      }
    }

    // move counters or remainingChecks
    String? halfmovePart = parts.isNotEmpty ? parts.removeAt(0) : null;
    (int, int)? earlyRemainingChecks;
    if (halfmovePart != null && halfmovePart.contains('+')) {
      earlyRemainingChecks = _parseRemainingChecks(halfmovePart);
      halfmovePart = parts.isNotEmpty ? parts.removeAt(0) : null;
    }
    final halfmoves = halfmovePart != null ? _parseSmallUint(halfmovePart) : 0;
    if (halfmoves == null) {
      throw const FenException(IllegalFenCause.halfmoveClock);
    }

    final fullmovesPart = parts.isNotEmpty ? parts.removeAt(0) : null;
    final fullmoves =
        fullmovesPart != null ? _parseSmallUint(fullmovesPart) : 1;
    if (fullmoves == null) {
      throw const FenException(IllegalFenCause.fullmoveNumber);
    }

    final remainingChecksPart = parts.isNotEmpty ? parts.removeAt(0) : null;
    (int, int)? remainingChecks;
    if (remainingChecksPart != null) {
      if (earlyRemainingChecks != null) {
        throw const FenException(IllegalFenCause.remainingChecks);
      }
      remainingChecks = _parseRemainingChecks(remainingChecksPart);
    } else if (earlyRemainingChecks != null) {
      remainingChecks = earlyRemainingChecks;
    }

    if (parts.isNotEmpty) {
      throw const FenException(IllegalFenCause.format);
    }

    return Setup(
      board: board,
      pockets: pockets,
      turn: turn,
      castlingRights: castlingRights,
      epSquare: epSquare,
      halfmoves: halfmoves,
      fullmoves: fullmoves,
      remainingChecks: remainingChecks,
    );
  }

  /// Piece positions on the board.
  final Board board;

  /// Pockets in chess variants like [Crazyhouse].
  final Pockets? pockets;

  /// Side to move.
  final Side turn;

  /// Unmoved rooks positions used to determine castling rights.
  final SquareSet castlingRights;

  /// En passant target square.
  ///
  /// Valid target squares are on the third or sixth rank.
  final Square? epSquare;

  /// Number of half-moves since the last capture or pawn move.
  final int halfmoves;

  /// Current move number.
  final int fullmoves;

  /// Number of remainingChecks for white and black.
  final (int, int)? remainingChecks;

  /// Initial position setup.
  static const standard = Setup(
    board: Board.standard,
    turn: Side.white,
    castlingRights: SquareSet.corners,
    halfmoves: 0,
    fullmoves: 1,
  );

  /// FEN character for the side to move.
  String get turnLetter => turn.name[0];

  /// FEN representation of the setup.
  String get fen => [
        board.fen + (pockets != null ? _makePockets(pockets!) : ''),
        turnLetter,
        _makeCastlingFen(board, castlingRights),
        if (epSquare != null) epSquare!.name else '-',
        if (remainingChecks != null) _makeRemainingChecks(remainingChecks!),
        math.max(0, math.min(halfmoves, 9999)),
        math.max(1, math.min(fullmoves, 9999)),
      ].join(' ');

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Setup &&
            other.board == board &&
            other.turn == turn &&
            other.castlingRights == castlingRights &&
            other.epSquare == epSquare &&
            other.halfmoves == halfmoves &&
            other.fullmoves == fullmoves;
  }

  @override
  int get hashCode => Object.hash(
        board,
        turn,
        castlingRights,
        epSquare,
        halfmoves,
        fullmoves,
      );
}

/// Pockets (captured pieces) in chess variants like [Crazyhouse].
@immutable
class Pockets {
  /// Creates a new [Pockets] with the provided value.
  const Pockets({
    required this.value,
  });

  final BySide<ByRole<int>> value;

  /// An empty pocket.
  static const empty = Pockets(value: _emptyPocketsBySide);

  /// Gets the total number of pieces in the pocket.
  int get size => value.values
      .fold(0, (acc, e) => acc + e.values.fold(0, (acc, e) => acc + e));

  /// Gets the number of pieces of that [Side] and [Role] in the pocket.
  int of(Side side, Role role) {
    return value[side]![role]!;
  }

  /// Counts the number of pieces by [Role].
  int count(Role role) {
    return value[Side.white]![role]! + value[Side.black]![role]!;
  }

  /// Checks whether this side has at least 1 quality (any piece but a pawn).
  bool hasQuality(Side side) {
    final bySide = value[side]!;
    return bySide[Role.knight]! > 0 ||
        bySide[Role.bishop]! > 0 ||
        bySide[Role.rook]! > 0 ||
        bySide[Role.queen]! > 0 ||
        bySide[Role.king]! > 0;
  }

  /// Checks whether this side has at least 1 pawn.
  bool hasPawn(Side side) {
    return value[side]![Role.pawn]! > 0;
  }

  /// Increments the number of pieces in the pocket of that [Side] and [Role].
  Pockets increment(Side side, Role role) {
    final newPocket = value[side]!.add(role, of(side, role) + 1);
    return Pockets(value: value.add(side, newPocket));
  }

  /// Decrements the number of pieces in the pocket of that [Side] and [Role].
  Pockets decrement(Side side, Role role) {
    final newPocket = value[side]!.add(role, of(side, role) - 1);
    return Pockets(value: value.add(side, newPocket));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Pockets && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

Pockets _parsePockets(String pocketPart) {
  if (pocketPart.length > 64) {
    throw const FenException(IllegalFenCause.pockets);
  }
  Pockets pockets = Pockets.empty;
  for (int i = 0; i < pocketPart.length; i++) {
    final c = pocketPart[i];
    final piece = Piece.fromChar(c);
    if (piece == null) {
      throw const FenException(IllegalFenCause.pockets);
    }
    pockets = pockets.increment(piece.color, piece.role);
  }
  return pockets;
}

(int, int) _parseRemainingChecks(String part) {
  final parts = part.split('+');
  if (parts.length == 3 && parts[0] == '') {
    final white = _parseSmallUint(parts[1]);
    final black = _parseSmallUint(parts[2]);
    if (white == null || white > 3 || black == null || black > 3) {
      throw const FenException(IllegalFenCause.remainingChecks);
    }
    return (3 - white, 3 - black);
  } else if (parts.length == 2) {
    final white = _parseSmallUint(parts[0]);
    final black = _parseSmallUint(parts[1]);
    if (white == null || white > 3 || black == null || black > 3) {
      throw const FenException(IllegalFenCause.remainingChecks);
    }
    return (white, black);
  } else {
    throw const FenException(IllegalFenCause.remainingChecks);
  }
}

SquareSet _parseCastlingFen(Board board, String castlingPart) {
  SquareSet castlingRights = SquareSet.empty;
  if (castlingPart == '-') {
    return castlingRights;
  }
  for (final rune in castlingPart.runes) {
    final c = String.fromCharCode(rune);
    final lower = c.toLowerCase();
    final lowerCode = lower.codeUnitAt(0);
    final side = c == lower ? Side.black : Side.white;
    final rank = side == Side.white ? Rank.first : Rank.eighth;
    if ('a'.codeUnitAt(0) <= lowerCode && lowerCode <= 'h'.codeUnitAt(0)) {
      castlingRights = castlingRights.withSquare(
          Square.fromCoords(File(lowerCode - 'a'.codeUnitAt(0)), rank));
    } else if (lower == 'k' || lower == 'q') {
      final rooksAndKings = (board.bySide(side) & SquareSet.backrankOf(side)) &
          (board.rooks | board.kings);
      final candidate = lower == 'k'
          ? rooksAndKings.squares.lastOrNull
          : rooksAndKings.squares.firstOrNull;
      castlingRights = castlingRights.withSquare(
          candidate != null && board.rooks.has(candidate)
              ? candidate
              : Square.fromCoords(lower == 'k' ? File.h : File.a, rank));
    } else {
      throw const FenException(IllegalFenCause.castling);
    }
  }
  if (Side.values.any((color) =>
      SquareSet.backrankOf(color).intersect(castlingRights).size > 2)) {
    throw const FenException(IllegalFenCause.castling);
  }
  return castlingRights;
}

String _makePockets(Pockets pockets) {
  final wPart = [
    for (final r in Role.values)
      ...List.filled(pockets.of(Side.white, r), r.letter)
  ].join();
  final bPart = [
    for (final r in Role.values)
      ...List.filled(pockets.of(Side.black, r), r.letter)
  ].join();
  return '[${wPart.toUpperCase()}$bPart]';
}

String _makeCastlingFen(Board board, SquareSet castlingRights) {
  final buffer = StringBuffer();
  for (final color in Side.values) {
    final backrank = SquareSet.backrankOf(color);
    final king = board.kingOf(color);
    final candidates =
        board.byPiece(Piece(color: color, role: Role.rook)) & backrank;
    for (final rook in (castlingRights & backrank).squaresReversed) {
      if (rook == candidates.first && king != null && rook < king) {
        buffer.write(color == Side.white ? 'Q' : 'q');
      } else if (rook == candidates.last && king != null && king < rook) {
        buffer.write(color == Side.white ? 'K' : 'k');
      } else {
        final file = rook.file.name;
        buffer.write(color == Side.white ? file.toUpperCase() : file);
      }
    }
  }
  final fen = buffer.toString();
  return fen != '' ? fen : '-';
}

String _makeRemainingChecks((int, int) checks) {
  final (white, black) = checks;
  return '$white+$black';
}

int? _parseSmallUint(String str) =>
    RegExp(r'^\d{1,4}$').hasMatch(str) ? int.parse(str) : null;

int _nthIndexOf(String haystack, String needle, int nth) {
  int index = haystack.indexOf(needle);
  int n = nth;
  while (n-- > 0) {
    if (index == -1) break;
    index = haystack.indexOf(needle, index + needle.length);
  }
  return index;
}

const ByRole<int> _emptyPocket = IMapConst({
  Role.pawn: 0,
  Role.knight: 0,
  Role.bishop: 0,
  Role.rook: 0,
  Role.queen: 0,
  Role.king: 0,
});

const BySide<ByRole<int>> _emptyPocketsBySide = IMapConst({
  Side.white: _emptyPocket,
  Side.black: _emptyPocket,
});
