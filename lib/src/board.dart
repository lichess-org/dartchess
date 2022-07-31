import './square_set.dart';
import './models.dart';

/// Piece positions on a board.
class Board {
  Board({
    required occupied,
    required promoted,
    required SquareSet white,
    required SquareSet black,
    required SquareSet pawn,
    required SquareSet knight,
    required SquareSet bishop,
    required SquareSet rook,
    required SquareSet queen,
    required SquareSet king,
  })  : _occupied = occupied,
        _promoted = promoted,
        _byColor = {
          Color.white: white,
          Color.black: black,
        },
        _byRole = {
          Role.pawn: pawn,
          Role.knight: knight,
          Role.bishop: bishop,
          Role.rook: rook,
          Role.queen: queen,
          Role.king: king,
        };

  /// Standard chess starting position.
  Board._makeStandard()
      : _occupied = SquareSet(0xffff00000000ffff),
        _promoted = SquareSet.empty,
        _byColor = {
          Color.white: SquareSet(0xffff),
          Color.black: SquareSet(0xffff000000000000),
        },
        _byRole = {
          Role.pawn: SquareSet(0x00ff00000000ff00),
          Role.knight: SquareSet(0x4200000000000042),
          Role.bishop: SquareSet(0x2400000000000024),
          Role.rook: SquareSet(0x8100000000000081),
          Role.queen: SquareSet(0x0800000000000008),
          Role.king: SquareSet(0x1000000000000010),
        };

  Board._makeEmpty()
      : _occupied = SquareSet.empty,
        _promoted = SquareSet.empty,
        _byColor = {
          Color.white: SquareSet.empty,
          Color.black: SquareSet.empty,
        },
        _byRole = {
          Role.pawn: SquareSet.empty,
          Role.knight: SquareSet.empty,
          Role.bishop: SquareSet.empty,
          Role.rook: SquareSet.empty,
          Role.queen: SquareSet.empty,
          Role.king: SquareSet.empty,
        };

  static final standard = Board._makeStandard();
  static final empty = Board._makeEmpty();

  SquareSet _occupied;
  SquareSet _promoted;
  final Map<Color, SquareSet> _byColor;
  final Map<Role, SquareSet> _byRole;

  Board clone() {
    return Board(
      occupied: _occupied,
      promoted: _promoted,
      white: white,
      black: black,
      pawn: pawn,
      knight: knight,
      bishop: bishop,
      rook: rook,
      queen: queen,
      king: king,
    );
  }

  SquareSet get occupied => _occupied;
  SquareSet get promoted => _promoted;
  SquareSet get white => _byColor[Color.white]!;
  SquareSet get black => _byColor[Color.black]!;
  SquareSet get pawn => _byRole[Role.pawn]!;
  SquareSet get knight => _byRole[Role.knight]!;
  SquareSet get bishop => _byRole[Role.bishop]!;
  SquareSet get rook => _byRole[Role.rook]!;
  SquareSet get queen => _byRole[Role.queen]!;
  SquareSet get king => _byRole[Role.king]!;

  Iterable<Tuple<int, Piece>> get pieces sync* {
    for (final square in occupied.squares) {
      yield Tuple(square, pieceAt(square)!);
    }
  }

  Color? colorAt(int square) {
    if (white.has(square)) {
      return Color.white;
    } else if (black.has(square)) {
      return Color.black;
    } else {
      return null;
    }
  }

  Role? roleAt(int square) {
    for (final role in Role.values) {
      if (_byRole[role]!.has(square)) {
        return role;
      }
    }
    return null;
  }

  Piece? pieceAt(int square) {
    final color = colorAt(square);
    if (color == null) {
      return null;
    }
    final role = roleAt(square)!;
    final prom = promoted.has(square);
    return Piece(color: color, role: role, promoted: prom);
  }

  void setPieceAt(int square, Piece piece) {
    _occupied = _occupied.withSquare(square);
    _byColor[piece.color] = _byColor[piece.color]!.withSquare(square);
    _byRole[piece.role] = _byRole[piece.role]!.withSquare(square);
    if (piece.promoted) _promoted = _promoted.withSquare(square);
  }

  @override
  bool operator ==(Object other) {
    return other is Board &&
        other.runtimeType == runtimeType &&
        other.occupied == occupied &&
        other.promoted == promoted &&
        other.white == white &&
        other.black == black &&
        other.pawn == pawn &&
        other.knight == knight &&
        other.bishop == bishop &&
        other.rook == rook &&
        other.queen == queen &&
        other.king == king;
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        occupied,
        promoted,
        white,
        black,
        pawn,
        knight,
        bishop,
        rook,
        queen,
        king,
      );
}
