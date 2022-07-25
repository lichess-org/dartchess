import './square_set.dart';
import './models.dart';

/// Piece positions on a board.
class Board {
  /// Standard chess starting position.
  const Board.makeStandard()
      : occupied = const SquareSet(0xffff00000000ffff),
        promoted = SquareSet.empty,
        _byColor = const {
          Color.white: SquareSet(0xffff),
          Color.black: SquareSet(0xffff000000000000),
        },
        _byRole = const {
          Role.pawn: SquareSet(0x00ff00000000ff00),
          Role.knight: SquareSet(0x4200000000000042),
          Role.bishop: SquareSet(0x2400000000000024),
          Role.rook: SquareSet(0x8100000000000081),
          Role.queen: SquareSet(0x0800000000000008),
          Role.king: SquareSet(0x1000000000000010),
        };

  const Board.makeEmpty()
      : occupied = SquareSet.empty,
        promoted = SquareSet.empty,
        _byColor = const {
          Color.white: SquareSet.empty,
          Color.black: SquareSet.empty,
        },
        _byRole = const {
          Role.pawn: SquareSet.empty,
          Role.knight: SquareSet.empty,
          Role.bishop: SquareSet.empty,
          Role.rook: SquareSet.empty,
          Role.queen: SquareSet.empty,
          Role.king: SquareSet.empty,
        };

  static const standard = Board.makeStandard();
  static const empty = Board.makeEmpty();

  final SquareSet occupied;
  final SquareSet promoted;
  final Map<Color, SquareSet> _byColor;
  final Map<Role, SquareSet> _byRole;

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
}
