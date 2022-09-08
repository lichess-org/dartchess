import 'dart:math' as math;
import './square_set.dart';
import './models.dart';
import './board.dart';
import './utils.dart';
import './constants.dart';

/// A not necessarily legal position.
class Setup {
  /// Piece positions on the board.
  final Board board;

  /// Pockets in chess variants like [Crazyhouse].
  final Pockets? pockets;

  /// Side to move.
  final Color turn;

  /// Unmoved rooks positions used to determine castling rights.
  final SquareSet unmovedRooks;

  /// En passant target square.
  ///
  /// Valid target squares are on the third or sixth rank.
  final Square? epSquare;

  /// Number of half-moves since the last capture or pawn move.
  final int halfmoves;

  /// Current move number.
  final int fullmoves;

  /// Number of remainingChecks for white (`item1`) and black (`item2`).
  final Tuple2<int, int>? remainingChecks;

  const Setup({
    required this.board,
    this.pockets,
    required this.turn,
    required this.unmovedRooks,
    this.epSquare,
    required this.halfmoves,
    required this.fullmoves,
    this.remainingChecks,
  });

  static const standard = Setup(
    board: Board.standard,
    turn: Color.white,
    unmovedRooks: SquareSet.corners,
    halfmoves: 0,
    fullmoves: 1,
  );

  /// Parse Forsyth-Edwards-Notation and returns a Setup.
  ///
  /// The parser is relaxed:
  ///
  /// * Supports X-FEN and Shredder-FEN for castling right notation.
  /// * Accepts missing FEN fields (except the board) and fills them with
  ///   default values of `8/8/8/8/8/8/8/8 w - - 0 1`.
  /// * Accepts multiple spaces and underscores (`_`) as separators between
  ///   FEN fields.
  ///
  /// Throws a [FenError] if the provided FEN is not valid.
  factory Setup.parseFen(String fen) {
    final parts = fen.split(RegExp(r'[\s_]+'));
    if (parts.isEmpty) throw FenError('ERR_FEN');

    // board and pockets
    final boardPart = parts.removeAt(0);
    Pockets? pockets;
    Board board;
    if (boardPart.endsWith(']')) {
      final pocketStart = boardPart.indexOf('[');
      if (pocketStart == -1) {
        throw FenError('ERR_FEN');
      }
      board = Board.parseFen(boardPart.substring(0, pocketStart));
      pockets = _parsePockets(boardPart.substring(pocketStart + 1, boardPart.length - 1));
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
    Color turn;
    if (parts.isEmpty) {
      turn = Color.white;
    } else {
      final turnPart = parts.removeAt(0);
      if (turnPart == 'w') {
        turn = Color.white;
      } else if (turnPart == 'b') {
        turn = Color.black;
      } else {
        throw FenError('ERR_TURN');
      }
    }

    // Castling
    SquareSet unmovedRooks;
    if (parts.isEmpty) {
      unmovedRooks = SquareSet.empty;
    } else {
      final castlingPart = parts.removeAt(0);
      unmovedRooks = _parseCastlingFen(board, castlingPart);
    }

    // En passant square
    Square? epSquare;
    if (parts.isNotEmpty) {
      final epPart = parts.removeAt(0);
      if (epPart != '-') {
        epSquare = parseSquare(epPart);
        if (epSquare == null) throw FenError('ERR_EP_SQUARE');
      }
    }

    // move counters or remainingChecks
    String? halfmovePart = parts.isNotEmpty ? parts.removeAt(0) : null;
    Tuple2<int, int>? earlyRemainingChecks;
    if (halfmovePart != null && halfmovePart.contains('+')) {
      earlyRemainingChecks = _parseRemainingChecks(halfmovePart);
      halfmovePart = parts.isNotEmpty ? parts.removeAt(0) : null;
    }
    final halfmoves = halfmovePart != null ? _parseSmallUint(halfmovePart) : 0;
    if (halfmoves == null) {
      throw FenError('ERR_HALFMOVES');
    }

    final fullmovesPart = parts.isNotEmpty ? parts.removeAt(0) : null;
    final fullmoves = fullmovesPart != null ? _parseSmallUint(fullmovesPart) : 1;
    if (fullmoves == null) {
      throw FenError('ERR_FULLMOVES');
    }

    final remainingChecksPart = parts.isNotEmpty ? parts.removeAt(0) : null;
    Tuple2<int, int>? remainingChecks;
    if (remainingChecksPart != null) {
      if (earlyRemainingChecks != null) {
        throw FenError('ERR_REMAINING_CHECKS');
      }
      remainingChecks = _parseRemainingChecks(remainingChecksPart);
    } else if (earlyRemainingChecks != null) {
      remainingChecks = earlyRemainingChecks;
    }

    if (parts.isNotEmpty) {
      throw FenError('ERR_FEN');
    }

    return Setup(
      board: board,
      pockets: pockets,
      turn: turn,
      unmovedRooks: unmovedRooks,
      epSquare: epSquare,
      halfmoves: halfmoves,
      fullmoves: fullmoves,
      remainingChecks: remainingChecks,
    );
  }

  String get turnLetter => turn.name[0];

  String get fen => [
        board.fen + (pockets != null ? _makePockets(pockets!) : ''),
        turnLetter,
        _makeCastlingFen(board, unmovedRooks),
        epSquare != null ? toAlgebraic(epSquare!) : '-',
        ...(remainingChecks != null ? [_makeRemainingChecks(remainingChecks!)] : []),
        math.max(0, math.min(halfmoves, 9999)),
        math.max(1, math.min(fullmoves, 9999)),
      ].join(' ');

  @override
  bool operator ==(Object other) {
    return other is Setup &&
        other.board == board &&
        other.turn == turn &&
        other.unmovedRooks == unmovedRooks &&
        other.epSquare == epSquare &&
        other.halfmoves == halfmoves &&
        other.fullmoves == fullmoves;
  }

  @override
  int get hashCode => Object.hash(
        board,
        turn,
        unmovedRooks,
        epSquare,
        halfmoves,
        fullmoves,
      );
}

class Pockets {
  const Pockets({
    required this.value,
  });

  final ByColor<ByRole<int>> value;

  static const empty = Pockets(value: {
    Color.white: {
      Role.pawn: 0,
      Role.knight: 0,
      Role.bishop: 0,
      Role.rook: 0,
      Role.queen: 0,
      Role.king: 0,
    },
    Color.black: {
      Role.pawn: 0,
      Role.knight: 0,
      Role.bishop: 0,
      Role.rook: 0,
      Role.queen: 0,
      Role.king: 0,
    },
  });

  int of(Color color, Role role) {
    return value[color]![role]!;
  }

  int count(Role role) {
    return value[Color.white]![role]! + value[Color.black]![role]!;
  }

  bool hasQuality(Color color) {
    final byColor = value[color]!;
    return byColor[Role.knight]! > 0 ||
        byColor[Role.bishop]! > 0 ||
        byColor[Role.rook]! > 0 ||
        byColor[Role.queen]! > 0 ||
        byColor[Role.king]! > 0;
  }

  bool hasPawn(Color color) {
    return value[color]![Role.pawn]! > 0;
  }

  Pockets increment(Color color, Role role) {
    return Pockets(
        value: Map.unmodifiable({
      ...value,
      color: {
        ...value[color]!,
        role: of(color, role) + 1,
      },
    }));
  }

  Pockets decrement(Color color, Role role) {
    return Pockets(
        value: Map.unmodifiable({
      ...value,
      color: {
        ...value[color]!,
        role: of(color, role) - 1,
      },
    }));
  }

  int get size => value.values.fold(0, (acc, e) => acc + e.values.fold(0, (acc, e) => acc + e));
}

Pockets _parsePockets(String pocketPart) {
  if (pocketPart.length > 64) {
    throw FenError('ERR_POCKETS');
  }
  Pockets pockets = Pockets.empty;
  for (int i = 0; i < pocketPart.length; i++) {
    final c = pocketPart[i];
    final piece = Piece.fromChar(c);
    if (piece == null) {
      throw FenError('ERR_POCKETS');
    }
    pockets = pockets.increment(piece.color, piece.role);
  }
  return pockets;
}

Tuple2<int, int> _parseRemainingChecks(String part) {
  final parts = part.split('+');
  if (parts.length == 3 && parts[0] == '') {
    final white = _parseSmallUint(parts[1]);
    final black = _parseSmallUint(parts[2]);
    if (white == null || white > 3 || black == null || black > 3) {
      throw FenError('ERR_REMAINING_CHECKS');
    }
    return Tuple2(3 - white, 3 - black);
  } else if (parts.length == 2) {
    final white = _parseSmallUint(parts[0]);
    final black = _parseSmallUint(parts[1]);
    if (white == null || white > 3 || black == null || black > 3) {
      throw FenError('ERR_REMAINING_CHECKS');
    }
    return Tuple2(white, black);
  } else {
    throw FenError('ERR_REMAINING_CHECKS');
  }
}

SquareSet _parseCastlingFen(Board board, String castlingPart) {
  SquareSet unmovedRooks = SquareSet.empty;
  if (castlingPart == '-') {
    return unmovedRooks;
  }
  for (int i = 0; i < castlingPart.length; i++) {
    final c = castlingPart[i];
    final lower = c.toLowerCase();
    final color = c == lower ? Color.black : Color.white;
    final backrankMask = SquareSet.backrankOf(color);
    final backrank = backrankMask & board.byColor(color);

    Iterable<Square> candidates;
    if (lower == 'q') {
      candidates = backrank.squares;
    } else if (lower == 'k') {
      candidates = backrank.squaresReversed;
    } else if ('a'.compareTo(lower) <= 0 && lower.compareTo('h') <= 0) {
      candidates = (SquareSet.fromFile(lower.codeUnitAt(0) - 'a'.codeUnitAt(0)) & backrank).squares;
    } else {
      throw FenError('ERR_CASTLING');
    }
    for (final square in candidates) {
      if (board.kings.has(square)) break;
      if (board.rooks.has(square)) {
        unmovedRooks = unmovedRooks.withSquare(square);
        break;
      }
    }
  }
  if ((SquareSet.fromRank(0) & unmovedRooks).size > 2 ||
      (SquareSet.fromRank(7) & unmovedRooks).size > 2) {
    throw FenError('ERR_CASTLING');
  }
  return unmovedRooks;
}

String _makePockets(Pockets pockets) {
  final wPart =
      [for (final r in Role.values) ...List.filled(pockets.of(Color.white, r), r.char)].join('');
  final bPart =
      [for (final r in Role.values) ...List.filled(pockets.of(Color.black, r), r.char)].join('');
  return '[${wPart.toUpperCase()}$bPart]';
}

String _makeCastlingFen(Board board, SquareSet unmovedRooks) {
  String fen = '';
  for (final color in Color.values) {
    final backrank = SquareSet.backrankOf(color);
    final king = board.kingOf(color);
    final candidates = board.byPiece(Piece(color: color, role: Role.rook)) & backrank;
    for (final rook in (unmovedRooks & candidates).squaresReversed) {
      if (rook == candidates.first && king != null && rook < king) {
        fen += color == Color.white ? 'Q' : 'q';
      } else if (rook == candidates.last && king != null && king < rook) {
        fen += color == Color.white ? 'K' : 'k';
      } else {
        final file = kFileNames[squareFile(rook)];
        fen += color == Color.white ? file.toUpperCase() : file;
      }
    }
  }
  return fen != '' ? fen : '-';
}

String _makeRemainingChecks(Tuple2<int, int> checks) => '${checks.item1}+${checks.item2}';

int? _parseSmallUint(String str) => RegExp(r'^\d{1,4}$').hasMatch(str) ? int.parse(str) : null;

int _nthIndexOf(String haystack, String needle, int n) {
  int index = haystack.indexOf(needle);
  while (n-- > 0) {
    if (index == -1) break;
    index = haystack.indexOf(needle, index + needle.length);
  }
  return index;
}
