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

  const Setup({
    required this.board,
    required this.turn,
    required this.unmovedRooks,
    this.epSquare,
    required this.halfmoves,
    required this.fullmoves,
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

    // board
    final boardPart = parts.removeAt(0);
    final board = Board.parseFen(boardPart);

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

    // halfmoves
    int halfmoves = 0;
    if (parts.isNotEmpty) {
      final int? parsed = _parseSmallUint(parts.removeAt(0));
      if (parsed == null) {
        throw FenError('ERR_HALFMOVES');
      } else {
        halfmoves = parsed;
      }
    }

    // fullmoves
    int fullmoves = 1;
    if (parts.isNotEmpty) {
      final int? parsed = _parseSmallUint(parts.removeAt(0));
      if (parsed == null) {
        throw FenError('ERR_FULLMOVES');
      } else {
        fullmoves = parsed;
      }
    }

    if (parts.isNotEmpty) {
      throw FenError('ERR_FEN');
    }

    return Setup(
      board: board,
      turn: turn,
      unmovedRooks: unmovedRooks,
      epSquare: epSquare,
      halfmoves: halfmoves,
      fullmoves: fullmoves,
    );
  }

  String get turnLetter => turn.name[0];

  String get fen => [
        board.fen,
        turnLetter,
        _makeCastlingFen(board, unmovedRooks),
        epSquare != null ? toAlgebraic(epSquare!) : '-',
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

int? _parseSmallUint(String str) => RegExp(r'^\d{1,4}$').hasMatch(str) ? int.parse(str) : null;
