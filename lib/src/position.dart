import './square_set.dart';
import './attacks.dart';
import './models.dart';
import './board.dart';
import './setup.dart';
import './utils.dart';

/// A playable chess or chess variant position.
///
/// See [Chess] for a concrete implementation.
abstract class Position {
  const Position({
    required this.board,
    required this.turn,
    required this.castles,
    this.epSquare,
    required this.halfmoves,
    required this.fullmoves,
  });

  /// Piece positions on the board.
  final Board board;

  /// Side to move.
  final Color turn;

  /// Castling paths and unmoved rooks.
  final Castles castles;

  /// En passant target square.
  final Square? epSquare;

  /// Number of half-moves since the last capture or pawn move.
  final int halfmoves;

  /// Current move number.
  final int fullmoves;

  const Position._standard()
      : board = Board.standard,
        turn = Color.white,
        castles = Castles.standard,
        epSquare = null,
        halfmoves = 0,
        fullmoves = 1;

  Position._fromSetupUnchecked(Setup setup)
      : board = setup.board,
        turn = setup.turn,
        castles = Castles.fromSetup(setup),
        epSquare = _validEpSquare(setup),
        halfmoves = setup.halfmoves,
        fullmoves = setup.fullmoves;

  bool get isVariantEnd;

  bool get isInsufficientMaterial =>
      Color.values.every((color) => hasInsufficientMaterial(color));

  Map<Square, SquareSet> get legalMoves {
    if (isVariantEnd) return Map.unmodifiable({});
    return Map.unmodifiable(
        {for (final s in board.byColor(turn).squares) s: legalMovesOf(s)});
  }

  bool hasInsufficientMaterial(Color color) {
    if (board
        .byColor(color)
        .intersect(board.pawns.union(board.rooksAndQueens))
        .isNotEmpty) return false;
    if (board.byColor(color).isIntersected(board.knights)) {
      return (board.byColor(color).size <= 2 &&
          board
              .byColor(opposite(color))
              .diff(board.kings)
              .diff(board.queens)
              .isEmpty);
    }
    if (board.byColor(color).isIntersected(board.bishops)) {
      final sameColor = !board.bishops.isIntersected(SquareSet.darkSquares) ||
          !board.bishops.isIntersected(SquareSet.lightSquares);
      return sameColor && board.pawns.isEmpty && board.knights.isEmpty;
    }
    return true;
  }

  SquareSet legalMovesOf(Square square) {
    if (isVariantEnd) return SquareSet.empty;
    final piece = board.pieceAt(square);
    if (piece == null || piece.color != turn) return SquareSet.empty;
    final king = board.kingOf(turn);
    if (king == null) return SquareSet.empty;

    final snipers = rookAttacks(king, SquareSet.empty)
        .intersect(board.rooksAndQueens)
        .union(bishopAttacks(king, SquareSet.empty)
            .intersect(board.bishopsAndQueens))
        .intersect(board.byColor(opposite(turn)));
    SquareSet blockers = SquareSet.empty;
    for (final sniper in snipers.squares) {
      final b = between(king, sniper).intersect(board.occupied);
      if (!b.moreThanOne) blockers = blockers.union(b);
    }
    final checkers = board.attacksTo(king, opposite(turn));

    SquareSet pseudo;
    SquareSet? legal;
    if (piece.role == Role.pawn) {
      pseudo =
          pawnAttacks(turn, square).intersect(board.byColor(opposite(turn)));
      final delta = turn == Color.white ? 8 : -8;
      final step = square + delta;
      if (0 <= step && step < 64 && !board.occupied.has(step)) {
        pseudo = pseudo.withSquare(step);
        final canDoubleStep =
            turn == Color.white ? square < 16 : square >= 64 - 16;
        final doubleStep = step + delta;
        if (canDoubleStep && !board.occupied.has(doubleStep)) {
          pseudo = pseudo.withSquare(doubleStep);
        }
        if (epSquare != null && _canCaptureEp(square)) {
          final pawn = epSquare! - delta;
          if (checkers.isEmpty || checkers.singleSquare == pawn) {
            legal = SquareSet.fromSquare(epSquare!);
          }
        }
      }
    } else if (piece.role == Role.bishop) {
      pseudo = bishopAttacks(square, board.occupied);
    } else if (piece.role == Role.knight) {
      pseudo = knightAttacks(square);
    } else if (piece.role == Role.rook) {
      pseudo = rookAttacks(square, board.occupied);
    } else if (piece.role == Role.queen) {
      pseudo = queenAttacks(square, board.occupied);
    } else {
      pseudo = kingAttacks(square);
    }

    pseudo = pseudo.diff(board.byColor(turn));

    if (piece.role == Role.king) {
      final occ = board.occupied.withoutSquare(square);
      for (final to in pseudo.squares) {
        if (board.attacksTo(to, opposite(turn), occupied: occ).isNotEmpty) {
          pseudo = pseudo.withoutSquare(to);
        }
      }
      return pseudo
          .union(_castlingDest(CastlingSide.queen, king, checkers))
          .union(_castlingDest(CastlingSide.king, king, checkers));
    }

    if (checkers.isNotEmpty) {
      final checker = checkers.singleSquare;
      if (checker == null) return SquareSet.empty;
      pseudo = pseudo.intersect(between(checker, king).withSquare(checker));
    }

    if (blockers.has(square)) pseudo = pseudo.intersect(ray(square, king));

    if (legal != null) pseudo = pseudo.union(legal);

    return pseudo;
  }

  SquareSet _castlingDest(CastlingSide side, Square king, SquareSet checkers) {
    if (checkers.isNotEmpty) return SquareSet.empty;
    final rook = castles.rookOf(turn, side);
    if (rook == null) return SquareSet.empty;
    if (castles.pathOf(turn, side).isIntersected(board.occupied)) {
      return SquareSet.empty;
    }

    final kingTo = _kingCastlesTo(turn, side);
    final kingPath = between(king, kingTo);
    final occ = board.occupied.withoutSquare(king);
    for (final sq in kingPath.squares) {
      if (board.attacksTo(sq, opposite(turn), occupied: occ).isNotEmpty) {
        return SquareSet.empty;
      }
    }
    final rookTo = _rookCastlesTo(turn, side);
    final after = board.occupied
        .toggleSquare(king)
        .toggleSquare(rook)
        .toggleSquare(rookTo);
    if (board.attacksTo(kingTo, opposite(turn), occupied: after).isNotEmpty) {
      return SquareSet.empty;
    }
    return SquareSet.fromSquare(rook);
  }

  bool _canCaptureEp(Square pawn) {
    if (epSquare == null) return false;
    if (!pawnAttacks(turn, pawn).has(epSquare!)) return false;
    final king = board.kingOf(turn);
    if (king == null) return true;
    final captured = epSquare! + (turn == Color.white ? -8 : 8);
    final occupied = board.occupied
        .toggleSquare(pawn)
        .toggleSquare(epSquare!)
        .toggleSquare(captured);
    return !board.attacksTo(king, opposite(turn)).isIntersected(occupied);
  }

  void _validate({bool? ignoreImpossibleCheck}) {
    if (board.occupied.isEmpty) {
      throw PositionError(IllegalSetup.empty);
    }
    if (board.kings.size != 2) {
      throw PositionError(IllegalSetup.kings);
    }
    final ourKing = board.kingOf(turn);
    if (ourKing == null) {
      throw PositionError(IllegalSetup.kings);
    }
    final otherKing = board.kingOf(opposite(turn));
    if (otherKing == null) {
      throw PositionError(IllegalSetup.kings);
    }
    if (board.attacksTo(otherKing, turn).isNotEmpty) {
      throw PositionError(IllegalSetup.oppositeCheck);
    }
    if (SquareSet.backranks.intersect(board.pawns).isNotEmpty) {
      throw PositionError(IllegalSetup.pawnsOnBackrank);
    }
    final skipImpossibleCheck = ignoreImpossibleCheck ?? false;
    if (!skipImpossibleCheck) {
      final checkers = board.attacksTo(ourKing, opposite(turn));
      if (checkers.isNotEmpty) {
        if (epSquare != null) {
          // The pushed pawn must be the only checker, or it has uncovered
          // check by a single sliding piece.
          final pushedTo = epSquare! ^ 8;
          final pushedFrom = epSquare! ^ 24;
          if (checkers.moreThanOne ||
              (checkers.first != pushedTo &&
                  board
                      .attacksTo(ourKing, opposite(turn),
                          occupied: board.occupied
                              .withoutSquare(pushedTo)
                              .withSquare(pushedFrom))
                      .isNotEmpty)) {
            throw PositionError(IllegalSetup.impossibleCheck);
          }
        } else {
          // Multiple sliding checkers aligned with king.
          if (checkers.size > 2 ||
              (checkers.size == 2 &&
                  ray(checkers.first!, checkers.last!).has(ourKing))) {
            throw PositionError(IllegalSetup.impossibleCheck);
          }
        }
      }
    }
  }
}

class Chess extends Position {
  Chess._fromSetupUnchecked(Setup setup) : super._fromSetupUnchecked(setup);
  const Chess._standard() : super._standard();

  static const standard = Chess._standard();

  @override
  bool get isVariantEnd => false;

  /// Set up a playable [Chess] position.
  ///
  /// Throws a [PositionError] if the [Setup] does not meet basic validity
  /// requirements.
  factory Chess.fromSetup(Setup setup) {
    final unchecked = Chess._fromSetupUnchecked(setup);
    unchecked._validate();
    return unchecked;
  }
}

enum IllegalSetup {
  /// There are no pieces on the board.
  empty,

  /// The player not to move is in check.
  oppositeCheck,

  /// There are impossibly many checkers, two sliding checkers are
  /// aligned, or check is not possible because the last move was a
  /// double pawn push.
  ///
  /// Such a position cannot be reached by any sequence of legal moves.
  impossibleCheck,

  /// There are pawns on the backrank. Only [Horde] allows players to
  /// have pawns on their own backrank.
  pawnsOnBackrank,

  /// A king is missing, or there are too many kings.
  kings,

  /// A variant specific rule is violated.
  variant,
}

/// Error when trying to create a [Position] from an illegal [Setup].
class PositionError implements Exception {
  final IllegalSetup cause;
  PositionError(this.cause);
}

enum CastlingSide {
  queen,
  king;
}

class Castles {
  final SquareSet unmovedRooks;

  /// Rooks positions pair.
  ///
  /// First item is queen side, second is king side.
  final ByColor<Tuple2<Square?, Square?>> rook;

  /// Squares between the white king and rooks.
  ///
  /// First item is queen side, second is king side.
  final ByColor<Tuple2<SquareSet, SquareSet>> path;

  const Castles({
    required this.unmovedRooks,
    required this.rook,
    required this.path,
  });

  static const standard = Castles(
    unmovedRooks: SquareSet.corners,
    rook: {Color.white: Tuple2(0, 7), Color.black: Tuple2(56, 63)},
    path: {
      Color.white:
          Tuple2(SquareSet(0x000000000000000e), SquareSet(0x0000000000000060)),
      Color.black:
          Tuple2(SquareSet(0x0e00000000000000), SquareSet(0x6000000000000000))
    },
  );

  static const empty = Castles(
    unmovedRooks: SquareSet.empty,
    rook: {Color.white: Tuple2(null, null), Color.black: Tuple2(null, null)},
    path: {
      Color.white: Tuple2(SquareSet.empty, SquareSet.empty),
      Color.black: Tuple2(SquareSet.empty, SquareSet.empty)
    },
  );

  factory Castles.fromSetup(Setup setup) {
    Castles castles = Castles.empty;
    final rooks = setup.unmovedRooks.intersect(setup.board.rooks);
    for (final color in Color.values) {
      final backrank = SquareSet.fromRank(color == Color.white ? 0 : 7);
      final king = setup.board.kingOf(color);
      if (king == null || !backrank.has(king)) continue;
      final side =
          rooks.intersect(setup.board.byColor(color)).intersect(backrank);
      if (side.first != null && side.first! < king) {
        castles = castles._add(color, CastlingSide.queen, king, side.first!);
      }
      if (side.last != null && king < side.last!) {
        castles = castles._add(color, CastlingSide.king, king, side.last!);
      }
    }
    return castles;
  }

  /// Gets the rook [Square] by color and castling side.
  Square? rookOf(Color color, CastlingSide side) =>
      side == CastlingSide.queen ? rook[color]!.item1 : rook[color]!.item2;

  /// Gets the squares that need to be empty so that castling is possible
  /// on the given side.
  ///
  /// We're assuming the player still has the required castling rigths.
  SquareSet pathOf(Color color, CastlingSide side) =>
      side == CastlingSide.queen ? path[color]!.item1 : path[color]!.item2;

  Castles discardRookAt(Square square) {
    final whiteRook = rook[Color.white]!;
    final blackRook = rook[Color.black]!;
    return unmovedRooks.has(square)
        ? _copyWith(
            unmovedRooks: unmovedRooks.withoutSquare(square),
            rook: {
              if (square <= 7)
                Color.white: whiteRook.item1 == square
                    ? whiteRook.withItem1(null)
                    : whiteRook.item2 == square
                        ? whiteRook.withItem2(null)
                        : whiteRook,
              if (square >= 56)
                Color.black: blackRook.item1 == square
                    ? blackRook.withItem1(null)
                    : blackRook.item2 == square
                        ? blackRook.withItem2(null)
                        : blackRook,
            },
          )
        : this;
  }

  Castles _add(Color color, CastlingSide side, Square king, Square rook) {
    final kingTo = _kingCastlesTo(color, side);
    final rookTo = _rookCastlesTo(color, side);
    final path = between(rook, rookTo)
        .withSquare(rookTo)
        .union(between(king, kingTo).withSquare(kingTo))
        .withoutSquare(king)
        .withoutSquare(rook);
    return _copyWith(
      unmovedRooks: unmovedRooks.withSquare(rook),
      rook: {
        color: side == CastlingSide.queen
            ? this.rook[color]!.withItem1(rook)
            : this.rook[color]!.withItem2(rook),
      },
      path: {
        color: side == CastlingSide.queen
            ? this.path[color]!.withItem1(path)
            : this.path[color]!.withItem2(path),
      },
    );
  }

  Castles _copyWith({
    SquareSet? unmovedRooks,
    ByColor<Tuple2<Square?, Square?>>? rook,
    ByColor<Tuple2<SquareSet, SquareSet>>? path,
  }) {
    return Castles(
      unmovedRooks: unmovedRooks ?? this.unmovedRooks,
      rook:
          rook != null ? Map.unmodifiable({...this.rook, ...rook}) : this.rook,
      path:
          path != null ? Map.unmodifiable({...this.path, ...path}) : this.path,
    );
  }

  @override
  toString() =>
      'Castles(unmovedRooks: $unmovedRooks, rook: $rook, path: $path)';

  @override
  bool operator ==(Object other) =>
      other is Castles &&
      other.unmovedRooks == unmovedRooks &&
      other.rook[Color.white] == rook[Color.white] &&
      other.rook[Color.black] == rook[Color.black] &&
      other.path[Color.white] == path[Color.white] &&
      other.path[Color.black] == path[Color.black];

  @override
  int get hashCode => Object.hash(unmovedRooks, rook[Color.white],
      rook[Color.black], path[Color.white], path[Color.black]);
}

Square _rookCastlesTo(Color color, CastlingSide side) {
  return color == Color.white
      ? (side == CastlingSide.queen ? 3 : 5)
      : side == CastlingSide.queen
          ? 59
          : 61;
}

Square _kingCastlesTo(Color color, CastlingSide side) {
  return color == Color.white
      ? (side == CastlingSide.queen ? 2 : 6)
      : side == CastlingSide.queen
          ? 58
          : 62;
}

Square? _validEpSquare(Setup setup) {
  if (setup.epSquare == null) return null;
  final epRank = setup.turn == Color.white ? 5 : 2;
  final forward = setup.turn == Color.white ? 8 : -8;
  if (squareRank(setup.epSquare!) != epRank) return null;
  if (setup.board.occupied.has(setup.epSquare! + forward)) return null;
  final pawn = setup.epSquare! - forward;
  if (!setup.board.pawns.has(pawn) ||
      !setup.board.byColor(opposite(setup.turn)).has(pawn)) return null;
  return setup.epSquare;
}
