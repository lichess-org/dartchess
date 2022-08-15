import './square_set.dart';
import './models.dart';
import './utils.dart';

/// [Piece] positions on a board.
class Board {
  const Board({
    required this.occupied,
    required this.promoted,
    required this.white,
    required this.black,
    required this.pawn,
    required this.knight,
    required this.bishop,
    required this.rook,
    required this.queen,
    required this.king,
  });

  /// All occupied squares.
  final SquareSet occupied;

  /// All squares occupied by pieces known to be promoted.
  final SquareSet promoted;

  /// All squares occupied by white pieces.
  final SquareSet white;

  /// All squares occupied by black pieces.
  final SquareSet black;

  /// All squares occupied by pawns.
  final SquareSet pawn;

  /// All squares occupied by knights..
  final SquareSet knight;

  /// All squares occupied by bishops...
  final SquareSet bishop;

  /// All squares occupied by rooks..
  final SquareSet rook;

  /// All squares occupied by queens..
  final SquareSet queen;

  /// All squares occupied by kings..
  final SquareSet king;

  /// Standard chess starting position.
  static const standard = Board(
      occupied: SquareSet(0xffff00000000ffff),
      promoted: SquareSet.empty,
      white: SquareSet(0xffff),
      black: SquareSet(0xffff000000000000),
      pawn: SquareSet(0x00ff00000000ff00),
      knight: SquareSet(0x4200000000000042),
      bishop: SquareSet(0x2400000000000024),
      rook: SquareSet(0x8100000000000081),
      queen: SquareSet(0x0800000000000008),
      king: SquareSet(0x1000000000000010));

  static const empty = Board(
      occupied: SquareSet.empty,
      promoted: SquareSet.empty,
      white: SquareSet.empty,
      black: SquareSet.empty,
      pawn: SquareSet.empty,
      knight: SquareSet.empty,
      bishop: SquareSet.empty,
      rook: SquareSet.empty,
      queen: SquareSet.empty,
      king: SquareSet.empty);

  /// Parse the board part of a FEN string and returns a Board.
  factory Board.parseFen(String boardFen) {
    Board board = Board.empty;
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
          board = board.setPieceAt(square, piece);
          file++;
        }
      }
    }
    if (rank != 0 || file != 8) throw InvalidFenException('ERR_BOARD');
    return board;
  }

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

  SquareSet byColor(Color color) {
    return color == Color.white ? white : black;
  }

  SquareSet byRole(Role role) {
    switch (role) {
      case Role.pawn:
        return pawn;
      case Role.knight:
        return knight;
      case Role.bishop:
        return bishop;
      case Role.rook:
        return rook;
      case Role.queen:
        return queen;
      case Role.king:
        return king;
    }
  }

  SquareSet byPiece(Piece piece) {
    return byColor(piece.color).intersect(byRole(piece.role));
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
      if (byRole(role).has(square)) {
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

  /// Finds the unique king of the given [color], if any.
  int? kingOf(Color color) {
    return byPiece(Piece(color: color, role: Role.king)).singleSquare;
  }

  Board setPieceAt(int square, Piece piece) {
    return _copyWith(
      occupied: occupied.withSquare(square),
      promoted: piece.promoted ? promoted.withSquare(square) : null,
      white: piece.color == Color.white ? white.withSquare(square) : null,
      black: piece.color == Color.black ? black.withSquare(square) : null,
      pawn: piece.role == Role.pawn ? pawn.withSquare(square) : null,
      knight: piece.role == Role.knight ? knight.withSquare(square) : null,
      bishop: piece.role == Role.bishop ? bishop.withSquare(square) : null,
      rook: piece.role == Role.rook ? rook.withSquare(square) : null,
      queen: piece.role == Role.queen ? queen.withSquare(square) : null,
      king: piece.role == Role.king ? king.withSquare(square) : null,
    );
  }

  Board _copyWith({
    SquareSet? occupied,
    SquareSet? promoted,
    SquareSet? white,
    SquareSet? black,
    SquareSet? pawn,
    SquareSet? knight,
    SquareSet? bishop,
    SquareSet? rook,
    SquareSet? queen,
    SquareSet? king,
  }) {
    return Board(
      occupied: occupied ?? this.occupied,
      promoted: promoted ?? this.promoted,
      white: white ?? this.white,
      black: black ?? this.black,
      pawn: pawn ?? this.pawn,
      knight: knight ?? this.knight,
      bishop: bishop ?? this.bishop,
      rook: rook ?? this.rook,
      queen: queen ?? this.queen,
      king: king ?? this.king,
    );
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
