import './board.dart';
import './square_set.dart';
import './models.dart';
import './setup.dart';
import './utils.dart';

class InvalidFenException implements Exception {
  final String message;
  InvalidFenException(this.message);
}

const kInitialBoardFEN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR';
const kInitialEPD = '$kInitialBoardFEN w KQkq -';
const kInitialFEN = '$kInitialEPD 0 1';
const kEmptyBoardFEN = '8/8/8/8/8/8/8/8';
const kEmptyEPD = '$kEmptyBoardFEN w - -';
const kEmptyFEN = '$kEmptyEPD 0 1';

Setup parseFen(String fen) {
  final parts = fen.split(RegExp(r'[\s_]+'));
  if (parts.isEmpty) throw InvalidFenException('ERR_FEN');

  // board
  final boardPart = parts.removeAt(0);
  final board = parseBoardFen(boardPart);

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
      throw InvalidFenException('ERR_TURN');
    }
  }

  // Castling
  SquareSet unmovedRooks;
  if (parts.isEmpty) {
    unmovedRooks = SquareSet.empty;
  } else {
    final castlingPart = parts.removeAt(0);
    unmovedRooks = parseCastlingFen(board, castlingPart);
  }

  // En passant square
  int? epSquare;
  if (parts.isNotEmpty) {
    final epPart = parts.removeAt(0);
    if (epPart != '-') {
      epSquare = parseSquare(epPart);
      if (epSquare == null) throw InvalidFenException('ERR_EP_SQUARE');
    }
  }

  // halfmoves
  int halfmoves = 0;
  if (parts.isNotEmpty) {
    final int? parsed = parseSmallUint(parts.removeAt(0));
    if (parsed == null) {
      throw InvalidFenException('ERR_HALFMOVES');
    } else {
      halfmoves = parsed;
    }
  }

  // fullmoves
  int fullmoves = 1;
  if (parts.isNotEmpty) {
    final int? parsed = parseSmallUint(parts.removeAt(0));
    if (parsed == null) {
      throw InvalidFenException('ERR_FULLMOVES');
    } else {
      fullmoves = parsed;
    }
  }

  if (parts.isNotEmpty) {
    throw InvalidFenException('ERR_FEN');
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

Board parseBoardFen(String boardFen) {
  final board = Board.empty();
  int rank = 7, file = 0;
  for (int i = 0; i < boardFen.length; i++) {
    final c = boardFen[i];
    if (c == '/' && file == 8) {
      file = 0;
      rank--;
    } else {
      final code = c.codeUnitAt(0);
      if (code < 57) {
        file += code - 48;
      } else {
        if (file >= 8 || rank < 0) throw InvalidFenException('ERR_BOARD');
        final square = file + rank * 8;
        final promoted = i + 1 < boardFen.length && boardFen[i + 1] == '~';
        final piece = _charToPiece(c, promoted);
        if (piece == null) throw InvalidFenException('ERR_BOARD');
        if (promoted) i++;
        board.setPieceAt(square, piece);
        file++;
      }
    }
  }
  if (rank != 0 || file != 8) throw InvalidFenException('ERR_BOARD');
  return board;
}

SquareSet parseCastlingFen(Board board, String castlingPart) {
  SquareSet unmovedRooks = SquareSet.empty;
  if (castlingPart == '-') {
    return unmovedRooks;
  }
  for (int i = 0; i < castlingPart.length; i++) {
    final c = castlingPart[i];
    final lower = c.toLowerCase();
    final color = c == lower ? Color.black : Color.white;
    final backrankMask = SquareSet.fromRank(color == Color.white ? 0 : 7);
    final backrank = backrankMask.intersect(board.byColor(color));

    Iterable<int> candidates;
    if (lower == 'q') {
      candidates = backrank.squares;
    } else if (lower == 'k') {
      candidates = backrank.squaresReversed;
    } else if ('a'.compareTo(lower) <= 0 && lower.compareTo('h') <= 0) {
      candidates = SquareSet.fromFile(lower.codeUnitAt(0) - 'a'.codeUnitAt(0))
          .intersect(backrank)
          .squares;
    } else {
      throw InvalidFenException('ERR_CASTLING');
    }
    for (final square in candidates) {
      if (board.king.has(square)) break;
      if (board.rook.has(square)) {
        unmovedRooks = unmovedRooks.withSquare(square);
        break;
      }
    }
  }
  if (SquareSet.fromRank(0).intersect(unmovedRooks).size > 2 ||
      SquareSet.fromRank(7).intersect(unmovedRooks).size > 2) {
    throw InvalidFenException('ERR_CASTLING');
  }
  return unmovedRooks;
}

Piece? _charToPiece(String ch, bool promoted) {
  final role = charToRole(ch);
  if (role != null) {
    return Piece(
        role: role,
        color: ch == ch.toLowerCase() ? Color.black : Color.white,
        promoted: promoted);
  }
  return null;
}

int? parseSmallUint(String str) =>
    RegExp(r'^\d{1,4}$').hasMatch(str) ? int.parse(str) : null;
