import 'board.dart';
import 'debug.dart';
import 'models.dart';
import 'position.dart';
import 'zobrist_tables.dart';

/// Zobrist hashing for [Position].
///
/// The hash of a given position is stable: changing hash values is considered
/// a breaking change.
///
/// The hash of a standard chess position is
/// [Polyglot](http://hgm.nubati.net/book_format.html) compatible, and the
/// variants extend it in the same way as
/// [shakmaty](https://docs.rs/shakmaty/latest/shakmaty/zobrist/index.html)
/// does.
///
/// Warning: Zobrist hashes have excellent collision resistance, but can be
/// forged efficiently.
extension ZobristHash on Position {
  /// Computes the Zobrist hash of the position from scratch.
  ///
  /// The hash includes the position, except halfmove clock and fullmove
  /// number. It is a signed integer whose bit pattern is the unsigned 64 bit
  /// hash; use [humanReadableZobristHash] to print it.
  int zobristHash({EnPassantMode mode = EnPassantMode.legal}) {
    var hash = _boardZobristHash(board);

    for (final square in board.promoted.squares) {
      hash ^= _zobristForPromoted(square);
    }

    final pockets = this.pockets;
    if (pockets != null) {
      for (final side in Side.values) {
        for (final role in Role.values) {
          hash ^= _zobristForPocket(side, role, pockets.of(side, role));
        }
      }
    }

    if (turn == Side.white) {
      hash ^= _zobristForWhiteTurn();
    }

    for (final side in Side.values) {
      for (final castlingSide in CastlingSide.values) {
        if (castles.rookOf(side, castlingSide) != null) {
          hash ^= _zobristForCastlingRight(side, castlingSide);
        }
      }
    }

    final epSquare = epSquareOf(mode);
    if (epSquare != null) {
      hash ^= _zobristForEnPassantFile(epSquare.file);
    }

    final position = this;
    if (position is ThreeCheck) {
      final (white, black) = position.remainingChecks;
      hash ^= _zobristForRemainingChecks(Side.white, white);
      hash ^= _zobristForRemainingChecks(Side.black, black);
    }

    return hash;
  }
}

/// The Zobrist mask of a [Piece] on a [Square].
int _zobristForPiece(Square square, Piece piece) =>
    pieceMasks[piece.color]![piece.role]![square];

/// The Zobrist mask of the white side to move.
int _zobristForWhiteTurn() => whiteTurnMask;

/// The Zobrist mask of a castling right.
int _zobristForCastlingRight(Side side, CastlingSide castlingSide) =>
    castlingRightMasks[side]![castlingSide]!;

/// The Zobrist mask of an en passant [File].
int _zobristForEnPassantFile(File file) => enPassantFileMasks[file];

/// The Zobrist mask of the number of checks a side still has to give in
/// [ThreeCheck].
int _zobristForRemainingChecks(Side side, int remaining) {
  final masks = remainingChecksMasks[side]!;
  // The masks encode the number of checks already given.
  final n = ~remaining;
  return ((n & 1) != 0 ? masks[0] : 0) ^ ((n >>> 1 & 1) != 0 ? masks[1] : 0);
}

/// The Zobrist mask of a piece known to be promoted, on a [Square].
int _zobristForPromoted(Square square) => promotedMasks[square];

/// The Zobrist mask of the number of [pieces] of a [Role] in a side's pocket.
int _zobristForPocket(Side side, Role role, int pieces) {
  final masks = pocketMasks[side]![role]!;
  var mask = 0;
  for (var bit = 0; bit < masks.length; bit++) {
    if (pieces >>> bit & 1 != 0) {
      mask ^= masks[bit];
    }
  }
  return mask;
}

int _boardZobristHash(Board board) {
  // Order optimized for cache efficiency.
  var hash = 0;
  for (final role in Role.values) {
    for (final side in [Side.black, Side.white]) {
      final piece = Piece(color: side, role: role);
      for (final square in board.byPiece(piece).squares) {
        hash ^= _zobristForPiece(square, piece);
      }
    }
  }
  return hash;
}
