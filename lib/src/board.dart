import 'package:meta/meta.dart';
import './square_set.dart';
import './models.dart';
import './attacks.dart';
import './utils.dart';

/// A board represented by several square sets for each piece.
@immutable
class Board {
  const Board({
    required this.occupied,
    required this.promoted,
    required this.sides,
    required this.roles,
  });

  /// All occupied squares.
  final SquareSet occupied;

  /// All squares occupied by pieces known to be promoted.
  ///
  /// This information is relevant in chess variants like [Crazyhouse].
  final SquareSet promoted;

  final BySide<SquareSet> sides;
  final ByRole<SquareSet> roles;

  /// Standard chess starting position.
  static const standard = Board(
      occupied: SquareSet(0xffff00000000ffff),
      promoted: SquareSet.empty,
      sides: {
        Side.white: SquareSet(0xffff),
        Side.black: SquareSet(0xffff000000000000),
      },
      roles: {
        Role.pawn: SquareSet(0x00ff00000000ff00),
        Role.knight: SquareSet(0x4200000000000042),
        Role.bishop: SquareSet(0x2400000000000024),
        Role.rook: SquareSet.corners,
        Role.queen: SquareSet(0x0800000000000008),
        Role.king: SquareSet(0x1000000000000010),
      });

  static const empty =
      Board(occupied: SquareSet.empty, promoted: SquareSet.empty, sides: {
    Side.white: SquareSet.empty,
    Side.black: SquareSet.empty,
  }, roles: {
    Role.pawn: SquareSet.empty,
    Role.knight: SquareSet.empty,
    Role.bishop: SquareSet.empty,
    Role.rook: SquareSet.empty,
    Role.queen: SquareSet.empty,
    Role.king: SquareSet.empty,
  });

  /// Parse the board part of a FEN string and returns a Board.
  ///
  /// Throws a [FenError] if the provided FEN string is not valid.
  factory Board.parseFen(String boardFen) {
    Board board = Board.empty;
    int rank = 7;
    int file = 0;
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
          if (file >= 8 || rank < 0) throw const FenError('ERR_BOARD');
          final square = file + rank * 8;
          final promoted = i + 1 < boardFen.length && boardFen[i + 1] == '~';
          final piece = _charToPiece(c, promoted);
          if (piece == null) throw const FenError('ERR_BOARD');
          if (promoted) i++;
          board = board.setPieceAt(square, piece);
          file++;
        }
      }
    }
    if (rank != 0 || file != 8) throw const FenError('ERR_BOARD');
    return board;
  }

  /// All squares occupied by white pieces.
  SquareSet get white => sides[Side.white]!;

  /// All squares occupied by black pieces.
  SquareSet get black => sides[Side.black]!;

  /// All squares occupied by pawns.
  SquareSet get pawns => roles[Role.pawn]!;

  /// All squares occupied by knights.
  SquareSet get knights => roles[Role.knight]!;

  /// All squares occupied by bishops.
  SquareSet get bishops => roles[Role.bishop]!;

  /// All squares occupied by rooks.
  SquareSet get rooks => roles[Role.rook]!;

  /// All squares occupied by queens.
  SquareSet get queens => roles[Role.queen]!;

  /// All squares occupied by kings.
  SquareSet get kings => roles[Role.king]!;

  SquareSet get rooksAndQueens => rooks | queens;
  SquareSet get bishopsAndQueens => bishops | queens;

  /// Board part of the Forsyth-Edwards-Notation.
  String get fen {
    final buffer = StringBuffer();
    int empty = 0;
    for (int rank = 7; rank >= 0; rank--) {
      for (int file = 0; file < 8; file++) {
        final square = file + rank * 8;
        final piece = pieceAt(square);
        if (piece == null) {
          empty++;
        } else {
          if (empty > 0) {
            buffer.write(empty.toString());
            empty = 0;
          }
          buffer.write(piece.fenChar);
        }

        if (file == 7) {
          if (empty > 0) {
            buffer.write(empty.toString());
            empty = 0;
          }
          if (rank != 0) buffer.write('/');
        }
      }
    }
    return buffer.toString();
  }

  /// An iterable of each [Piece] associated to its [Square].
  Iterable<Tuple2<Square, Piece>> get pieces sync* {
    for (final square in occupied.squares) {
      yield Tuple2(square, pieceAt(square)!);
    }
  }

  /// A [SquareSet] of all the pieces matching this [Side] and [Role].
  SquareSet piecesOf(Side side, Role role) {
    return bySide(side) & byRole(role);
  }

  /// Gets all squares occupied by [Side].
  SquareSet bySide(Side side) => sides[side]!;

  /// Gets all squares occupied by [Role].
  SquareSet byRole(Role role) => roles[role]!;

  /// Gets all squares occupied by [Piece].
  SquareSet byPiece(Piece piece) {
    return sides[piece.color]! & roles[piece.role]!;
  }

  /// Gets the [Side] at this [Square], if any.
  Side? sideAt(Square square) {
    if (sides[Side.white]!.has(square)) {
      return Side.white;
    } else if (sides[Side.black]!.has(square)) {
      return Side.black;
    } else {
      return null;
    }
  }

  /// Gets the [Role] at this [Square], if any.
  Role? roleAt(Square square) {
    for (final role in Role.values) {
      if (roles[role]!.has(square)) {
        return role;
      }
    }
    return null;
  }

  /// Gets the [Piece] at this [Square], if any.
  Piece? pieceAt(Square square) {
    final side = sideAt(square);
    if (side == null) {
      return null;
    }
    final role = roleAt(square)!;
    final prom = promoted.has(square);
    return Piece(color: side, role: role, promoted: prom);
  }

  /// Finds the unique king [Square] of the given [Side], if any.
  Square? kingOf(Side side) {
    return byPiece(Piece(color: side, role: Role.king)).singleSquare;
  }

  /// Finds the squares who are attacking `square` by the `attacker` [Side].
  SquareSet attacksTo(Square square, Side attacker, {SquareSet? occupied}) =>
      bySide(attacker).intersect(rookAttacks(square, occupied ?? this.occupied)
          .intersect(rooksAndQueens)
          .union(bishopAttacks(square, occupied ?? this.occupied)
              .intersect(bishopsAndQueens))
          .union(knightAttacks(square).intersect(knights))
          .union(kingAttacks(square).intersect(kings))
          .union(pawnAttacks(opposite(attacker), square).intersect(pawns)));

  /// Puts a [Piece] on a [Square] overriding the existing one, if any.
  Board setPieceAt(Square square, Piece piece) {
    return removePieceAt(square)._copyWith(
      occupied: occupied.withSquare(square),
      promoted: piece.promoted ? promoted.withSquare(square) : null,
      sides: {
        piece.color: sides[piece.color]!.withSquare(square),
      },
      roles: {
        piece.role: roles[piece.role]!.withSquare(square),
      },
    );
  }

  /// Removes the [Piece] at this [Square] if it exists.
  Board removePieceAt(Square square) {
    final piece = pieceAt(square);
    return piece != null
        ? _copyWith(
            occupied: occupied.withoutSquare(square),
            promoted: piece.promoted ? promoted.withoutSquare(square) : null,
            sides: {
              piece.color: sides[piece.color]!.withoutSquare(square),
            },
            roles: {
              piece.role: roles[piece.role]!.withoutSquare(square),
            },
          )
        : this;
  }

  Board withPromoted(SquareSet promoted) {
    return _copyWith(promoted: promoted);
  }

  Board _copyWith({
    SquareSet? occupied,
    SquareSet? promoted,
    BySide<SquareSet>? sides,
    ByRole<SquareSet>? roles,
  }) {
    return Board(
      occupied: occupied ?? this.occupied,
      promoted: promoted ?? this.promoted,
      sides: sides != null
          ? Map.unmodifiable({...this.sides, ...sides})
          : this.sides,
      roles: roles != null
          ? Map.unmodifiable({...this.roles, ...roles})
          : this.roles,
    );
  }

  @override
  String toString() => fen;

  @override
  bool operator ==(Object other) {
    return other is Board &&
        other.occupied == occupied &&
        other.promoted == promoted &&
        other.white == white &&
        other.black == black &&
        other.pawns == pawns &&
        other.knights == knights &&
        other.bishops == bishops &&
        other.rooks == rooks &&
        other.queens == queens &&
        other.kings == kings;
  }

  @override
  int get hashCode => Object.hash(occupied, promoted, white, black, pawns,
      knights, bishops, rooks, queens, kings);
}

Piece? _charToPiece(String ch, bool promoted) {
  final role = Role.fromChar(ch);
  if (role != null) {
    return Piece(
        role: role,
        color: ch == ch.toLowerCase() ? Side.black : Side.white,
        promoted: promoted);
  }
  return null;
}
