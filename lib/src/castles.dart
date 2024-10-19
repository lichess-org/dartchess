import 'package:meta/meta.dart';

import 'attacks.dart';
import 'models.dart';
import 'setup.dart';
import 'square_set.dart';

/// Represents the castling rights of a game.
@immutable
abstract class Castles {
  /// Creates a new [Castles] instance.
  const factory Castles({
    required SquareSet castlingRights,
    Square? whiteRookQueenSide,
    Square? whiteRookKingSide,
    Square? blackRookQueenSide,
    Square? blackRookKingSide,
    required SquareSet whitePathQueenSide,
    required SquareSet whitePathKingSide,
    required SquareSet blackPathQueenSide,
    required SquareSet blackPathKingSide,
  }) = _Castles;

  const Castles._({
    required this.castlingRights,
    Square? whiteRookQueenSide,
    Square? whiteRookKingSide,
    Square? blackRookQueenSide,
    Square? blackRookKingSide,
    required SquareSet whitePathQueenSide,
    required SquareSet whitePathKingSide,
    required SquareSet blackPathQueenSide,
    required SquareSet blackPathKingSide,
  })  : _whiteRookQueenSide = whiteRookQueenSide,
        _whiteRookKingSide = whiteRookKingSide,
        _blackRookQueenSide = blackRookQueenSide,
        _blackRookKingSide = blackRookKingSide,
        _whitePathQueenSide = whitePathQueenSide,
        _whitePathKingSide = whitePathKingSide,
        _blackPathQueenSide = blackPathQueenSide,
        _blackPathKingSide = blackPathKingSide;

  /// SquareSet of rooks that have not moved yet.
  final SquareSet castlingRights;

  final Square? _whiteRookQueenSide;
  final Square? _whiteRookKingSide;
  final Square? _blackRookQueenSide;
  final Square? _blackRookKingSide;
  final SquareSet _whitePathQueenSide;
  final SquareSet _whitePathKingSide;
  final SquareSet _blackPathQueenSide;
  final SquareSet _blackPathKingSide;

  static const standard = Castles(
    castlingRights: SquareSet.corners,
    whiteRookQueenSide: Square.a1,
    whiteRookKingSide: Square.h1,
    blackRookQueenSide: Square.a8,
    blackRookKingSide: Square.h8,
    whitePathQueenSide: SquareSet(0x000000000000000e),
    whitePathKingSide: SquareSet(0x0000000000000060),
    blackPathQueenSide: SquareSet(0x0e00000000000000),
    blackPathKingSide: SquareSet(0x6000000000000000),
  );

  static const empty = Castles(
    castlingRights: SquareSet.empty,
    whitePathQueenSide: SquareSet.empty,
    whitePathKingSide: SquareSet.empty,
    blackPathQueenSide: SquareSet.empty,
    blackPathKingSide: SquareSet.empty,
  );

  static const horde = Castles(
    castlingRights: SquareSet(0x8100000000000000),
    blackRookKingSide: Square.h8,
    blackRookQueenSide: Square.a8,
    whitePathKingSide: SquareSet.empty,
    whitePathQueenSide: SquareSet.empty,
    blackPathQueenSide: SquareSet(0x0e00000000000000),
    blackPathKingSide: SquareSet(0x6000000000000000),
  );

  /// Creates a [Castles] instance from a [Setup].
  factory Castles.fromSetup(Setup setup) {
    Castles castles = Castles.empty;
    final rooks = setup.castlingRights & setup.board.rooks;
    for (final side in Side.values) {
      final backrank = SquareSet.backrankOf(side);
      final king = setup.board.kingOf(side);
      if (king == null || !backrank.has(king)) continue;
      final backrankRooks = rooks & setup.board.bySide(side) & backrank;
      if (backrankRooks.first != null && backrankRooks.first! < king) {
        castles =
            castles._add(side, CastlingSide.queen, king, backrankRooks.first!);
      }
      if (backrankRooks.last != null && king < backrankRooks.last!) {
        castles =
            castles._add(side, CastlingSide.king, king, backrankRooks.last!);
      }
    }
    return castles;
  }

  /// Gets rooks positions by side and castling side.
  BySide<ByCastlingSide<Square?>> get rooksPositions {
    return BySide({
      Side.white: ByCastlingSide({
        CastlingSide.queen: _whiteRookQueenSide,
        CastlingSide.king: _whiteRookKingSide,
      }),
      Side.black: ByCastlingSide({
        CastlingSide.queen: _blackRookQueenSide,
        CastlingSide.king: _blackRookKingSide,
      }),
    });
  }

  /// Gets rooks paths by side and castling side.
  BySide<ByCastlingSide<SquareSet>> get paths {
    return BySide({
      Side.white: ByCastlingSide({
        CastlingSide.queen: _whitePathQueenSide,
        CastlingSide.king: _whitePathKingSide,
      }),
      Side.black: ByCastlingSide({
        CastlingSide.queen: _blackPathQueenSide,
        CastlingSide.king: _blackPathKingSide,
      }),
    });
  }

  /// Gets the rook [Square] by side and castling side.
  Square? rookOf(Side side, CastlingSide cs) => switch (side) {
        Side.white => switch (cs) {
            CastlingSide.queen => _whiteRookQueenSide,
            CastlingSide.king => _whiteRookKingSide,
          },
        Side.black => switch (cs) {
            CastlingSide.queen => _blackRookQueenSide,
            CastlingSide.king => _blackRookKingSide,
          },
      };

  /// Gets the squares that need to be empty so that castling is possible
  /// on the given side.
  ///
  /// We're assuming the player still has the required castling rigths.
  SquareSet pathOf(Side side, CastlingSide cs) => switch (side) {
        Side.white => switch (cs) {
            CastlingSide.queen => _whitePathQueenSide,
            CastlingSide.king => _whitePathKingSide,
          },
        Side.black => switch (cs) {
            CastlingSide.queen => _blackPathQueenSide,
            CastlingSide.king => _blackPathKingSide,
          },
      };

  /// Returns a new [Castles] instance with the given rook discarded.
  Castles discardRookAt(Square square) {
    return copyWith(
      castlingRights: castlingRights.withoutSquare(square),
      whiteRookQueenSide:
          _whiteRookQueenSide == square ? null : _whiteRookQueenSide,
      whiteRookKingSide:
          _whiteRookKingSide == square ? null : _whiteRookKingSide,
      blackRookQueenSide:
          _blackRookQueenSide == square ? null : _blackRookQueenSide,
      blackRookKingSide:
          _blackRookKingSide == square ? null : _blackRookKingSide,
    );
  }

  /// Returns a new [Castles] instance with the given side discarded.
  Castles discardSide(Side side) {
    return copyWith(
      castlingRights: castlingRights.diff(SquareSet.backrankOf(side)),
      whiteRookQueenSide: side == Side.white ? null : _whiteRookQueenSide,
      whiteRookKingSide: side == Side.white ? null : _whiteRookKingSide,
      blackRookQueenSide: side == Side.black ? null : _blackRookQueenSide,
      blackRookKingSide: side == Side.black ? null : _blackRookKingSide,
    );
  }

  Castles _add(Side side, CastlingSide cs, Square king, Square rook) {
    final kingTo = kingCastlesTo(side, cs);
    final rookTo = rookCastlesTo(side, cs);
    final path = between(rook, rookTo)
        .withSquare(rookTo)
        .union(between(king, kingTo).withSquare(kingTo))
        .withoutSquare(king)
        .withoutSquare(rook);
    return copyWith(
      castlingRights: castlingRights.withSquare(rook),
      whiteRookQueenSide: side == Side.white && cs == CastlingSide.queen
          ? rook
          : _whiteRookQueenSide,
      whiteRookKingSide: side == Side.white && cs == CastlingSide.king
          ? rook
          : _whiteRookKingSide,
      blackRookQueenSide: side == Side.black && cs == CastlingSide.queen
          ? rook
          : _blackRookQueenSide,
      blackRookKingSide: side == Side.black && cs == CastlingSide.king
          ? rook
          : _blackRookKingSide,
      whitePathQueenSide:
          side == Side.white && cs == CastlingSide.queen ? path : null,
      whitePathKingSide:
          side == Side.white && cs == CastlingSide.king ? path : null,
      blackPathQueenSide:
          side == Side.black && cs == CastlingSide.queen ? path : null,
      blackPathKingSide:
          side == Side.black && cs == CastlingSide.king ? path : null,
    );
  }

  @override
  String toString() {
    return 'Castles(castlingRights: ${castlingRights.toHexString()})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Castles &&
          other.castlingRights == castlingRights &&
          other._whiteRookQueenSide == _whiteRookQueenSide &&
          other._whiteRookKingSide == _whiteRookKingSide &&
          other._blackRookQueenSide == _blackRookQueenSide &&
          other._blackRookKingSide == _blackRookKingSide &&
          other._whitePathQueenSide == _whitePathQueenSide &&
          other._whitePathKingSide == _whitePathKingSide &&
          other._blackPathQueenSide == _blackPathQueenSide &&
          other._blackPathKingSide == _blackPathKingSide;

  @override
  int get hashCode => Object.hash(
      castlingRights,
      _whiteRookQueenSide,
      _whiteRookKingSide,
      _blackRookQueenSide,
      _blackRookKingSide,
      _whitePathQueenSide,
      _whitePathKingSide,
      _blackPathQueenSide,
      _blackPathKingSide);

  Castles copyWith({
    SquareSet? castlingRights,
    Square? whiteRookQueenSide,
    Square? whiteRookKingSide,
    Square? blackRookQueenSide,
    Square? blackRookKingSide,
    SquareSet? whitePathQueenSide,
    SquareSet? whitePathKingSide,
    SquareSet? blackPathQueenSide,
    SquareSet? blackPathKingSide,
  });
}

/// Returns the square the rook moves to when castling.
Square rookCastlesTo(Side side, CastlingSide cs) => switch (side) {
      Side.white => switch (cs) {
          CastlingSide.queen => Square.d1,
          CastlingSide.king => Square.f1,
        },
      Side.black => switch (cs) {
          CastlingSide.queen => Square.d8,
          CastlingSide.king => Square.f8,
        },
    };

/// Returns the square the king moves to when castling.
Square kingCastlesTo(Side side, CastlingSide cs) => switch (side) {
      Side.white => switch (cs) {
          CastlingSide.queen => Square.c1,
          CastlingSide.king => Square.g1,
        },
      Side.black => switch (cs) {
          CastlingSide.queen => Square.c8,
          CastlingSide.king => Square.g8,
        },
    };

class _Castles extends Castles {
  const _Castles({
    required super.castlingRights,
    super.whiteRookQueenSide,
    super.whiteRookKingSide,
    super.blackRookQueenSide,
    super.blackRookKingSide,
    required super.whitePathQueenSide,
    required super.whitePathKingSide,
    required super.blackPathQueenSide,
    required super.blackPathKingSide,
  }) : super._();

  @override
  Castles copyWith({
    SquareSet? castlingRights,
    Object? whiteRookQueenSide = _uniqueObjectInstance,
    Object? whiteRookKingSide = _uniqueObjectInstance,
    Object? blackRookQueenSide = _uniqueObjectInstance,
    Object? blackRookKingSide = _uniqueObjectInstance,
    SquareSet? whitePathQueenSide,
    SquareSet? whitePathKingSide,
    SquareSet? blackPathQueenSide,
    SquareSet? blackPathKingSide,
  }) {
    return _Castles(
      castlingRights: castlingRights ?? this.castlingRights,
      whiteRookQueenSide: whiteRookQueenSide == _uniqueObjectInstance
          ? _whiteRookQueenSide
          : whiteRookQueenSide as Square?,
      whiteRookKingSide: whiteRookKingSide == _uniqueObjectInstance
          ? _whiteRookKingSide
          : whiteRookKingSide as Square?,
      blackRookQueenSide: blackRookQueenSide == _uniqueObjectInstance
          ? _blackRookQueenSide
          : blackRookQueenSide as Square?,
      blackRookKingSide: blackRookKingSide == _uniqueObjectInstance
          ? _blackRookKingSide
          : blackRookKingSide as Square?,
      whitePathQueenSide: whitePathQueenSide ?? _whitePathQueenSide,
      whitePathKingSide: whitePathKingSide ?? _whitePathKingSide,
      blackPathQueenSide: blackPathQueenSide ?? _blackPathQueenSide,
      blackPathKingSide: blackPathKingSide ?? _blackPathKingSide,
    );
  }
}

/// Unique object to use as a sentinel value in copyWith methods.
const _uniqueObjectInstance = Object();
