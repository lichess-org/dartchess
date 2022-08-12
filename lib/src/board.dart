import './square_set.dart';
import './models.dart';
import './utils.dart';

/// [Piece] positions on a board.
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

  /// All occupied squares.
  SquareSet _occupied;
  /// All squares occupied by pieces known to be promoted.
  SquareSet _promoted;
  final Map<Color, SquareSet> _byColor;
  final Map<Role, SquareSet> _byRole;

  /// Standard chess starting position.
  Board.standard()
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

  Board.empty()
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

  factory Board.parseFen(String boardFen) {
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

  String get fen {
    String fen = '';
    int empty = 0;
    for (int rank = 7; rank >= 0; rank--) {
      for (int file = 0; file < 8; file++) {
        final square = file + rank * 8;
        final piece = pieceAt(square);
        if (piece == null) {
          empty++;
        } else {
          if (empty > 0) {
            fen += empty.toString();
            empty = 0;
          }
          fen += piece.fenChar;
        }

        if (file == 7) {
          if (empty > 0) {
            fen += empty.toString();
            empty = 0;
          }
          if (rank != 0) fen += '/';
        }
      }
    }
    return fen;
  }

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

  SquareSet byColor(Color color) {
    return _byColor[color]!;
  }

  SquareSet byPiece(Piece piece) {
    return _byColor[piece.color]!.intersect(_byRole[piece.role]!);
  }

  /// Finds the unique king of the given [color], if any.
  int? kingOf(Color color) {
    return byPiece(Piece(color: color, role: Role.king)).singleSquare;
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
