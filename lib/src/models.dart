import 'package:meta/meta.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import './square_set.dart';

/// The chessboard side, white or black.
enum Side {
  white,
  black;

  /// Gets the opposite side.
  Side get opposite => this == Side.white ? Side.black : Side.white;
}

/// The chessboard square color, light or dark.
enum SquareColor {
  light,
  dark;

  /// Gets the opposite color.
  SquareColor get opposite =>
      this == SquareColor.light ? SquareColor.dark : SquareColor.light;
}

/// The chessboard castling side.
enum CastlingSide {
  /// The queen side castling.
  queen,

  /// The king side castling.
  king;
}

/// Piece role, such as pawn, knight, etc.
enum Role {
  pawn,
  knight,
  bishop,
  rook,
  king,
  queen;

  /// Gets the role from a character.
  static Role? fromChar(String ch) {
    switch (ch.toLowerCase()) {
      case 'p':
        return Role.pawn;
      case 'n':
        return Role.knight;
      case 'b':
        return Role.bishop;
      case 'r':
        return Role.rook;
      case 'q':
        return Role.queen;
      case 'k':
        return Role.king;
      default:
        return null;
    }
  }

  /// Gets the role letter in lowercase (as for black piece in FEN notation).
  String get letter => switch (this) {
        Role.pawn => 'p',
        Role.knight => 'n',
        Role.bishop => 'b',
        Role.rook => 'r',
        Role.queen => 'q',
        Role.king => 'k',
      };

  /// Gets the role letter in uppercase (as for white piece in FEN notation).
  String get uppercaseLetter => switch (this) {
        Role.pawn => 'P',
        Role.knight => 'N',
        Role.bishop => 'B',
        Role.rook => 'R',
        Role.queen => 'Q',
        Role.king => 'K',
      };
}

/// A file of the chessboard.
extension type const File._(int value) implements int {
  /// Gets the chessboard [File] from a file index between 0 and 7.
  const File(this.value) : assert(value >= 0 && value < 8);

  /// Gets a [File] from its name in algebraic notation.
  ///
  /// Throws a [FormatException] if the algebraic notation is invalid.
  factory File.fromName(String algebraic) {
    final file = algebraic.codeUnitAt(0) - 97;
    if (file < 0 || file > 7) {
      throw FormatException('Invalid algebraic notation: $algebraic');
    }
    return File(file);
  }

  static const a = File(0);
  static const b = File(1);
  static const c = File(2);
  static const d = File(3);
  static const e = File(4);
  static const f = File(5);
  static const g = File(6);
  static const h = File(7);

  /// All files in ascending order.
  static const values = [a, b, c, d, e, f, g, h];

  static const _names = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

  /// The name of the file, such as 'a', 'b', 'c', etc.
  String get name => _names[value];

  /// Returns the file offset by [delta].
  ///
  /// Returns `null` if the resulting file is out of bounds.
  File? offset(int delta) {
    assert(delta >= -7 && delta <= 7);
    final newFile = value + delta;
    if (newFile < 0 || newFile > 7) {
      return null;
    }
    return File(newFile);
  }
}

/// A rank of the chessboard.
extension type const Rank._(int value) implements int {
  /// Gets the chessboard [Rank] from a rank index between 0 and 7.
  const Rank(this.value) : assert(value >= 0 && value < 8);

  /// Gets a [Rank] from its name in algebraic notation.
  ///
  /// Throws a [FormatException] if the algebraic notation is invalid.
  factory Rank.fromName(String algebraic) {
    final rank = algebraic.codeUnitAt(0) - 49;
    if (rank < 0 || rank > 7) {
      throw FormatException('Invalid algebraic notation: $algebraic');
    }
    return Rank(rank);
  }

  static const first = Rank(0);
  static const second = Rank(1);
  static const third = Rank(2);
  static const fourth = Rank(3);
  static const fifth = Rank(4);
  static const sixth = Rank(5);
  static const seventh = Rank(6);
  static const eighth = Rank(7);

  /// All ranks in ascending order.
  static const values = [
    first,
    second,
    third,
    fourth,
    fifth,
    sixth,
    seventh,
    eighth
  ];

  static const _names = ['1', '2', '3', '4', '5', '6', '7', '8'];

  /// The name of the rank, such as '1', '2', '3', etc.
  String get name => _names[value];

  /// Returns the rank offset by [delta].
  ///
  /// Returns `null` if the resulting rank is out of bounds.
  Rank? offset(int delta) {
    assert(delta >= -7 && delta <= 7);
    final newRank = value + delta;
    if (newRank < 0 || newRank > 7) {
      return null;
    }
    return Rank(newRank);
  }
}

/// A square of the chessboard.
///
/// The square is represented with an integer ranging from 0 to 63, using a
/// little-endian rank-file mapping (LERF):
/// ```
///  8 | 56 57 58 59 60 61 62 63
///  7 | 48 49 50 51 52 53 54 55
///  6 | 40 41 42 43 44 45 46 47
///  5 | 32 33 34 35 36 37 38 39
///  4 | 24 25 26 27 28 29 30 31
///  3 | 16 17 18 19 20 21 22 23
///  2 | 8  9  10 11 12 13 14 15
///  1 | 0  1  2  3  4  5  6  7
///    -------------------------
///      a  b  c  d  e  f  g  h
/// ```
///
/// See also:
/// - [File]
/// - [Rank]
/// - [SquareSet] for the manipulation of sets of squares.
extension type const Square._(int value) implements int {
  /// Gets the chessboard [Square] from a square index between 0 and 63.
  const Square(this.value) : assert(value >= 0 && value < 64);

  /// Gets a [Square] from its name in algebraic notation.
  ///
  /// Throws a [FormatException] if the algebraic notation is invalid.
  factory Square.fromName(String algebraic) {
    if (algebraic.length != 2) {
      throw FormatException('Invalid algebraic notation: $algebraic');
    }
    final file = algebraic.codeUnitAt(0) - 97;
    final rank = algebraic.codeUnitAt(1) - 49;
    if (file < 0 || file > 7 || rank < 0 || rank > 7) {
      throw FormatException('Invalid algebraic notation: $algebraic');
    }
    return Square(file | (rank << 3));
  }

  /// Gets a [Square] from its file and rank.
  factory Square.fromCoords(File file, Rank rank) => Square(file | (rank << 3));

  /// Parses a square name in algebraic notation.
  ///
  /// Returns either a [Square] or `null` if the algebraic notation is invalid.
  static Square? parse(String algebraic) {
    if (algebraic.length != 2) return null;
    final file = algebraic.codeUnitAt(0) - 97;
    final rank = algebraic.codeUnitAt(1) - 49;
    if (file < 0 || file > 7 || rank < 0 || rank > 7) return null;
    return Square(file | (rank << 3));
  }

  /// All squares on the chessboard, from a1 to h8.
  static const values = [
    a1, b1, c1, d1, e1, f1, g1, h1,
    a2, b2, c2, d2, e2, f2, g2, h2,
    a3, b3, c3, d3, e3, f3, g3, h3,
    a4, b4, c4, d4, e4, f4, g4, h4,
    a5, b5, c5, d5, e5, f5, g5, h5,
    a6, b6, c6, d6, e6, f6, g6, h6,
    a7, b7, c7, d7, e7, f7, g7, h7,
    a8, b8, c8, d8, e8, f8, g8, h8
  ];

  /// The file of the square on the board.
  File get file => File(value & 0x7);

  /// The rank of the square on the board.
  Rank get rank => Rank(value >> 3);

  /// Unique identifier of the square, using pure algebraic notation.
  String get name => file.name + rank.name;

  /// Returns the square offset by [delta].
  ///
  /// Returns `null` if the resulting square is out of bounds.
  Square? offset(int delta) {
    assert(delta >= -63 && delta <= 63);
    final newSquare = value + delta;
    if (newSquare < 0 || newSquare > 63) {
      return null;
    }
    return Square(newSquare);
  }

  /// Return the bitwise XOR of the numeric square representation.
  Square xor(Square other) => Square(value ^ other.value);

  static const a1 = Square(0);
  static const b1 = Square(1);
  static const c1 = Square(2);
  static const d1 = Square(3);
  static const e1 = Square(4);
  static const f1 = Square(5);
  static const g1 = Square(6);
  static const h1 = Square(7);
  static const a2 = Square(8);
  static const b2 = Square(9);
  static const c2 = Square(10);
  static const d2 = Square(11);
  static const e2 = Square(12);
  static const f2 = Square(13);
  static const g2 = Square(14);
  static const h2 = Square(15);
  static const a3 = Square(16);
  static const b3 = Square(17);
  static const c3 = Square(18);
  static const d3 = Square(19);
  static const e3 = Square(20);
  static const f3 = Square(21);
  static const g3 = Square(22);
  static const h3 = Square(23);
  static const a4 = Square(24);
  static const b4 = Square(25);
  static const c4 = Square(26);
  static const d4 = Square(27);
  static const e4 = Square(28);
  static const f4 = Square(29);
  static const g4 = Square(30);
  static const h4 = Square(31);
  static const a5 = Square(32);
  static const b5 = Square(33);
  static const c5 = Square(34);
  static const d5 = Square(35);
  static const e5 = Square(36);
  static const f5 = Square(37);
  static const g5 = Square(38);
  static const h5 = Square(39);
  static const a6 = Square(40);
  static const b6 = Square(41);
  static const c6 = Square(42);
  static const d6 = Square(43);
  static const e6 = Square(44);
  static const f6 = Square(45);
  static const g6 = Square(46);
  static const h6 = Square(47);
  static const a7 = Square(48);
  static const b7 = Square(49);
  static const c7 = Square(50);
  static const d7 = Square(51);
  static const e7 = Square(52);
  static const f7 = Square(53);
  static const g7 = Square(54);
  static const h7 = Square(55);
  static const a8 = Square(56);
  static const b8 = Square(57);
  static const c8 = Square(58);
  static const d8 = Square(59);
  static const e8 = Square(60);
  static const f8 = Square(61);
  static const g8 = Square(62);
  static const h8 = Square(63);
}

typedef BySide<T> = IMap<Side, T>;
typedef ByRole<T> = IMap<Role, T>;
typedef ByCastlingSide<T> = IMap<CastlingSide, T>;

/// Describes a chess piece kind by its color and role.
enum PieceKind {
  whitePawn(Side.white, Role.pawn),
  whiteKnight(Side.white, Role.knight),
  whiteBishop(Side.white, Role.bishop),
  whiteRook(Side.white, Role.rook),
  whiteQueen(Side.white, Role.queen),
  whiteKing(Side.white, Role.king),
  blackPawn(Side.black, Role.pawn),
  blackKnight(Side.black, Role.knight),
  blackBishop(Side.black, Role.bishop),
  blackRook(Side.black, Role.rook),
  blackQueen(Side.black, Role.queen),
  blackKing(Side.black, Role.king);

  const PieceKind(this.side, this.role);

  final Side side;
  final Role role;
}

/// Describes a chess piece by its color, role and promotion status.
@immutable
class Piece {
  const Piece({
    required this.color,
    required this.role,
    this.promoted = false,
  });

  final Side color;
  final Role role;
  final bool promoted;

  static Piece? fromChar(String ch) {
    final role = Role.fromChar(ch);
    if (role != null) {
      return Piece(
          role: role, color: ch.toLowerCase() == ch ? Side.black : Side.white);
    }
    return null;
  }

  /// Gets the piece kind.
  PieceKind get kind => switch (role) {
        Role.pawn =>
          color == Side.white ? PieceKind.whitePawn : PieceKind.blackPawn,
        Role.knight =>
          color == Side.white ? PieceKind.whiteKnight : PieceKind.blackKnight,
        Role.bishop =>
          color == Side.white ? PieceKind.whiteBishop : PieceKind.blackBishop,
        Role.rook =>
          color == Side.white ? PieceKind.whiteRook : PieceKind.blackRook,
        Role.queen =>
          color == Side.white ? PieceKind.whiteQueen : PieceKind.blackQueen,
        Role.king =>
          color == Side.white ? PieceKind.whiteKing : PieceKind.blackKing,
      };

  /// Gets the FEN character of this piece.
  ///
  /// For example, a white pawn is `P`, a black knight is `n`.
  String get fenChar {
    String r = role.letter;
    if (color == Side.white) r = r.toUpperCase();
    if (promoted) r += '~';
    return r;
  }

  Piece copyWith({
    Side? color,
    Role? role,
    bool? promoted,
  }) {
    return Piece(
      color: color ?? this.color,
      role: role ?? this.role,
      promoted: promoted ?? this.promoted,
    );
  }

  @override
  String toString() {
    return '${color.name}${role.name}';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Piece &&
            other.runtimeType == runtimeType &&
            color == other.color &&
            role == other.role &&
            promoted == other.promoted;
  }

  @override
  int get hashCode => Object.hash(color, role, promoted);

  static const whitePawn = Piece(color: Side.white, role: Role.pawn);
  static const whiteKnight = Piece(color: Side.white, role: Role.knight);
  static const whiteBishop = Piece(color: Side.white, role: Role.bishop);
  static const whiteRook = Piece(color: Side.white, role: Role.rook);
  static const whiteQueen = Piece(color: Side.white, role: Role.queen);
  static const whiteKing = Piece(color: Side.white, role: Role.king);

  static const blackPawn = Piece(color: Side.black, role: Role.pawn);
  static const blackKnight = Piece(color: Side.black, role: Role.knight);
  static const blackBishop = Piece(color: Side.black, role: Role.bishop);
  static const blackRook = Piece(color: Side.black, role: Role.rook);
  static const blackQueen = Piece(color: Side.black, role: Role.queen);
  static const blackKing = Piece(color: Side.black, role: Role.king);
}

/// Base class for a chess move.
///
/// A move can be either a [NormalMove] or a [DropMove].
@immutable
sealed class Move {
  const Move({
    required this.to,
  });

  /// The target square of this move.
  final Square to;

  /// Gets the UCI notation of this move.
  String get uci;

  /// Parses a UCI string into a move.
  ///
  /// Will return a [NormalMove] or a [DropMove] depending on the UCI string.
  ///
  /// Returns `null` if UCI string is not valid.
  static Move? parse(String str) {
    if (str[1] == '@' && str.length == 4) {
      final role = Role.fromChar(str[0]);
      final to = Square.parse(str.substring(2));
      if (role != null && to != null) return DropMove(to: to, role: role);
    } else if (str.length == 4 || str.length == 5) {
      final from = Square.parse(str.substring(0, 2));
      final to = Square.parse(str.substring(2, 4));
      Role? promotion;
      if (str.length == 5) {
        promotion = Role.fromChar(str[4]);
        if (promotion == null) {
          return null;
        }
      }
      if (from != null && to != null) {
        return NormalMove(from: from, to: to, promotion: promotion);
      }
    }
    return null;
  }

  /// Returns `true` if [square] is a square of this move.
  bool hasSquare(Square square);

  /// Returns an iterable of all squares involved in this move.
  Iterable<Square> get squares;

  @override
  String toString() {
    return 'Move($uci)';
  }
}

/// Represents a chess move, which is possibly a promotion.
@immutable
class NormalMove extends Move {
  const NormalMove({
    required this.from,
    required super.to,
    this.promotion,
  });

  /// Constructs a [NormalMove] from a UCI string.
  ///
  /// Throws a [FormatException] if the UCI string is invalid.
  factory NormalMove.fromUci(String uci) {
    final from = Square.parse(uci.substring(0, 2));
    final to = Square.parse(uci.substring(2, 4));
    Role? promotion;
    if (uci.length == 5) {
      promotion = Role.fromChar(uci[4]);
    }
    if (from != null && to != null) {
      return NormalMove(from: from, to: to, promotion: promotion);
    }
    throw FormatException('Invalid UCI notation: $uci');
  }

  /// The origin square of this move.
  final Square from;

  /// The role of the promoted piece, if any.
  final Role? promotion;

  @override
  bool hasSquare(Square square) => square == from || square == to;

  @override
  Iterable<Square> get squares => [from, to];

  /// Returns a copy of this move with a [promotion] role.
  NormalMove withPromotion(Role? promotion) =>
      NormalMove(from: from, to: to, promotion: promotion);

  /// Gets UCI notation, like `g1f3` for a normal move, `a7a8q` for promotion to a queen.
  @override
  String get uci =>
      from.name + to.name + (promotion != null ? promotion!.letter : '');

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other.runtimeType == runtimeType && hashCode == other.hashCode;
  }

  @override
  int get hashCode => Object.hash(from, to, promotion);
}

/// Represents a drop move.
@immutable
class DropMove extends Move {
  /// Constructs a [DropMove] from a target square and a role.
  const DropMove({
    required super.to,
    required this.role,
  });

  /// Constructs a [DropMove] from a UCI string.
  ///
  /// Throws a [FormatException] if the UCI string is invalid.
  factory DropMove.fromUci(String uci) {
    final role = Role.fromChar(uci[0]);
    final to = Square.parse(uci.substring(2));
    if (role != null && to != null) {
      return DropMove(to: to, role: role);
    }
    throw FormatException('Invalid UCI notation: $uci');
  }

  /// The [Role] of the dropped piece.
  final Role role;

  @override
  bool hasSquare(Square square) => square == to;

  @override
  Iterable<Square> get squares => [to];

  /// Gets UCI notation of the drop, like `Q@f7`.
  @override
  String get uci => '${role.uppercaseLetter}@${to.name}';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other.runtimeType == runtimeType && hashCode == other.hashCode;
  }

  @override
  int get hashCode => Object.hash(to, role);
}

/// An enumeration of the possible causes of an illegal FEN string.
enum IllegalFenCause {
  /// The FEN string is not in the correct format.
  format,

  /// The board part of the FEN string is invalid.
  board,

  /// The turn part of the FEN string is invalid.
  turn,

  /// The castling part of the FEN string is invalid.
  castling,

  /// The en passant part of the FEN string is invalid.
  enPassant,

  /// The halfmove clock part of the FEN string is invalid.
  halfmoveClock,

  /// The fullmove number part of the FEN string is invalid.
  fullmoveNumber,

  /// The remaining checks part of the FEN string is invalid.
  remainingChecks,

  /// The pockets part of the FEN string is invalid.
  pockets,
}

/// An exception thrown when trying to parse an invalid FEN string.
@immutable
class FenException implements Exception {
  /// Constructs a [FenException] with a [cause].
  const FenException(this.cause);

  /// The cause of the exception.
  final IllegalFenCause cause;

  @override
  String toString() => 'FenException: ${cause.name}';
}

/// Exception thrown when trying to play an illegal move.
@immutable
class PlayException implements Exception {
  /// Constructs a [PlayException] with a [message].
  const PlayException(this.message);

  /// The exception message.
  final String message;

  @override
  String toString() => 'PlayException: $message';
}

/// Enumeration of the possible causes of an illegal setup.
enum IllegalSetupCause {
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

  /// There are pawns on the backrank.
  pawnsOnBackrank,

  /// A king is missing, or there are too many kings.
  kings,

  /// A variant specific rule is violated.
  variant,
}

/// Exception thrown when trying to create a [Position] from an illegal [Setup].
@immutable
class PositionSetupException implements Exception {
  /// Constructs a [PositionSetupException] with a [cause].
  const PositionSetupException(this.cause);

  /// The cause of the exception.
  final IllegalSetupCause cause;

  static const empty = PositionSetupException(IllegalSetupCause.empty);
  static const oppositeCheck =
      PositionSetupException(IllegalSetupCause.oppositeCheck);
  static const impossibleCheck =
      PositionSetupException(IllegalSetupCause.impossibleCheck);
  static const pawnsOnBackrank =
      PositionSetupException(IllegalSetupCause.pawnsOnBackrank);
  static const kings = PositionSetupException(IllegalSetupCause.kings);
  static const variant = PositionSetupException(IllegalSetupCause.variant);

  @override
  String toString() => 'PositionSetupException: ${cause.name}';
}

/// Represents the different possible rules of chess and its variants
enum Rule {
  chess,
  antichess,
  kingofthehill,
  threecheck,
  atomic,
  horde,
  racingKings,
  crazyhouse;

  /// Parses a PGN header variant tag
  static Rule? fromPgn(String? variant) {
    switch ((variant ?? 'chess').toLowerCase()) {
      case 'chess':
      case 'chess960':
      case 'chess 960':
      case 'standard':
      case 'from position':
      case 'classical':
      case 'normal':
      case 'fischerandom': // Cute Chess
      case 'fischerrandom':
      case 'fischer random':
      case 'wild/0':
      case 'wild/1':
      case 'wild/2':
      case 'wild/3':
      case 'wild/4':
      case 'wild/5':
      case 'wild/6':
      case 'wild/7':
      case 'wild/8':
      case 'wild/8a':
        return Rule.chess;
      case 'crazyhouse':
      case 'crazy house':
      case 'house':
      case 'zh':
        return Rule.crazyhouse;
      case 'king of the hill':
      case 'koth':
      case 'kingofthehill':
        return Rule.kingofthehill;
      case 'three-check':
      case 'three check':
      case 'threecheck':
      case 'three check chess':
      case '3-check':
      case '3 check':
      case '3check':
        return Rule.threecheck;
      case 'antichess':
      case 'anti chess':
      case 'anti':
        return Rule.antichess;
      case 'atomic':
      case 'atom':
      case 'atomic chess':
        return Rule.atomic;
      case 'horde':
      case 'horde chess':
        return Rule.horde;
      case 'racing kings':
      case 'racingkings':
      case 'racing':
      case 'race':
        return Rule.racingKings;
      default:
        return null;
    }
  }
}
