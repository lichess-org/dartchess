import './square_set.dart';
import './attacks.dart';
import './models.dart';
import './board.dart';
import './setup.dart';

/// A playable chess or chess variant position.
///
/// See [Chess] for a concrete implementation.
abstract class Position {
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

  const Position({
    required this.board,
    required this.turn,
    required this.castles,
    this.epSquare,
    required this.halfmoves,
    required this.fullmoves,
  });
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
