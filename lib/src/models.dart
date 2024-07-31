import 'package:meta/meta.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import './utils.dart';
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

/// The chessboard castling side, queen or king side.
enum CastlingSide {
  queen,
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

  @Deprecated('Use `letter` instead.')
  String get char => letter;

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

  /// Constructs a [File] from an algebraic notation, such as 'a', 'b', 'c', etc.
  ///
  /// Throws a [FormatException] if the algebraic notation is invalid.
  factory File.fromAlgebraic(String algebraic) {
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

  /// The Algebraic Notation of the file, such as 'a', 'b', 'c', etc.
  String get algebraicNotation => _names[value];
}

/// A rank of the chessboard.
extension type const Rank._(int value) implements int {
  /// Gets the chessboard [Rank] from a rank index between 0 and 7.
  const Rank(this.value) : assert(value >= 0 && value < 8);

  /// Constructs a [Rank] from an algebraic notation, such as '1', '2', '3', etc.
  ///
  /// Throws a [FormatException] if the algebraic notation is invalid.
  factory Rank.fromAlgebraic(String algebraic) {
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

  /// The Algebraic Notation of the rank, such as '1', '2', '3', etc.
  String get algebraicNotation => _names[value];
}

/// A square of the chessboard.
///
/// Square values are between 0 and 63, representing the squares from a1 to h8.
///
/// See also:
/// - [SquareSet] for the manipulation of sets of squares.
extension type const Square._(int value) implements int {
  const Square(this.value) : assert(value >= 0 && value < 64);

  /// Constructs a [Square] from an algebraic notation, such as 'a1', 'b2', etc.
  ///
  /// Throws a [FormatException] if the algebraic notation is invalid.
  factory Square.fromAlgebraic(String algebraic) {
    final file = algebraic.codeUnitAt(0) - 97;
    final rank = algebraic.codeUnitAt(1) - 49;
    if (file < 0 || file > 7 || rank < 0 || rank > 7) {
      throw FormatException('Invalid algebraic notation: $algebraic');
    }
    return Square(rank * 8 + file);
  }

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

  /// The file of the square on the board.
  File get file => File(value & 0x7);

  /// The rank of the square on the board.
  Rank get rank => Rank(value >> 3);

  /// The Zero-based, numeric coordinates of the square on the board.
  Coord get coord => Coord(value & 0x7, value >> 3);

  /// The Algebraic Notation of the square, such as 'a1', 'b2', etc.
  String get algebraicNotation =>
      file.algebraicNotation + rank.algebraicNotation;

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

  static const values = [
    a1,
    b1,
    c1,
    d1,
    e1,
    f1,
    g1,
    h1,
    a2,
    b2,
    c2,
    d2,
    e2,
    f2,
    g2,
    h2,
    a3,
    b3,
    c3,
    d3,
    e3,
    f3,
    g3,
    h3,
    a4,
    b4,
    c4,
    d4,
    e4,
    f4,
    g4,
    h4,
    a5,
    b5,
    c5,
    d5,
    e5,
    f5,
    g5,
    h5,
    a6,
    b6,
    c6,
    d6,
    e6,
    f6,
    g6,
    h6,
    a7,
    b7,
    c7,
    d7,
    e7,
    f7,
    g7,
    h7,
    a8,
    b8,
    c8,
    d8,
    e8,
    f8,
    g8,
    h8
  ];
}

/// Zero-based numeric chessboard coordinates.
///
/// For instance a1 is (0, 0), a2 is (0, 1), etc.
extension type const Coord._((int x, int y) value) {
  /// Constructs a [Coord] from a pair of integers ranging from 0 to 7.
  const Coord(int x, int y) : this._new((x, y));

  const Coord._new(this.value)
      : assert(value == (0, 0) ||
            value == (0, 1) ||
            value == (0, 2) ||
            value == (0, 3) ||
            value == (0, 4) ||
            value == (0, 5) ||
            value == (0, 6) ||
            value == (0, 7) ||
            value == (1, 0) ||
            value == (1, 1) ||
            value == (1, 2) ||
            value == (1, 3) ||
            value == (1, 4) ||
            value == (1, 5) ||
            value == (1, 6) ||
            value == (1, 7) ||
            value == (2, 0) ||
            value == (2, 1) ||
            value == (2, 2) ||
            value == (2, 3) ||
            value == (2, 4) ||
            value == (2, 5) ||
            value == (2, 6) ||
            value == (2, 7) ||
            value == (3, 0) ||
            value == (3, 1) ||
            value == (3, 2) ||
            value == (3, 3) ||
            value == (3, 4) ||
            value == (3, 5) ||
            value == (3, 6) ||
            value == (3, 7) ||
            value == (4, 0) ||
            value == (4, 1) ||
            value == (4, 2) ||
            value == (4, 3) ||
            value == (4, 4) ||
            value == (4, 5) ||
            value == (4, 6) ||
            value == (4, 7) ||
            value == (5, 0) ||
            value == (5, 1) ||
            value == (5, 2) ||
            value == (5, 3) ||
            value == (5, 4) ||
            value == (5, 5) ||
            value == (5, 6) ||
            value == (5, 7) ||
            value == (6, 0) ||
            value == (6, 1) ||
            value == (6, 2) ||
            value == (6, 3) ||
            value == (6, 4) ||
            value == (6, 5) ||
            value == (6, 6) ||
            value == (6, 7) ||
            value == (7, 0) ||
            value == (7, 1) ||
            value == (7, 2) ||
            value == (7, 3) ||
            value == (7, 4) ||
            value == (7, 5) ||
            value == (7, 6) ||
            value == (7, 7));

  /// The file of the coordinates.
  File get file => File(value.$1);

  /// The rank of the coordinates.
  Rank get rank => Rank(value.$2);

  /// Gets the square from the coordinates.
  Square get square => Square(value.$2 * 8 + value.$1);

  /// All possible coordinates on the chessboard.
  static const values = [
    Coord(0, 0),
    Coord(0, 1),
    Coord(0, 2),
    Coord(0, 3),
    Coord(0, 4),
    Coord(0, 5),
    Coord(0, 6),
    Coord(0, 7),
    Coord(1, 0),
    Coord(1, 1),
    Coord(1, 2),
    Coord(1, 3),
    Coord(1, 4),
    Coord(1, 5),
    Coord(1, 6),
    Coord(1, 7),
    Coord(2, 0),
    Coord(2, 1),
    Coord(2, 2),
    Coord(2, 3),
    Coord(2, 4),
    Coord(2, 5),
    Coord(2, 6),
    Coord(2, 7),
    Coord(3, 0),
    Coord(3, 1),
    Coord(3, 2),
    Coord(3, 3),
    Coord(3, 4),
    Coord(3, 5),
    Coord(3, 6),
    Coord(3, 7),
    Coord(4, 0),
    Coord(4, 1),
    Coord(4, 2),
    Coord(4, 3),
    Coord(4, 4),
    Coord(4, 5),
    Coord(4, 6),
    Coord(4, 7),
    Coord(5, 0),
    Coord(5, 1),
    Coord(5, 2),
    Coord(5, 3),
    Coord(5, 4),
    Coord(5, 5),
    Coord(5, 6),
    Coord(5, 7),
    Coord(6, 0),
    Coord(6, 1),
    Coord(6, 2),
    Coord(6, 3),
    Coord(6, 4),
    Coord(6, 5),
    Coord(6, 6),
    Coord(6, 7),
    Coord(7, 0),
    Coord(7, 1),
    Coord(7, 2),
    Coord(7, 3),
    Coord(7, 4),
    Coord(7, 5),
    Coord(7, 6),
    Coord(7, 7)
  ];
}

typedef BySide<T> = IMap<Side, T>;
typedef ByRole<T> = IMap<Role, T>;
typedef ByCastlingSide<T> = IMap<CastlingSide, T>;

/// Represents a piece kind, which is a tuple of side and role.
typedef PieceKind = (Side side, Role role);

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

  /// Gets the piece kind, which is a tuple of side and role.
  PieceKind get kind => (color, role);

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

  /// Constructs a [Move] from an UCI string.
  ///
  /// Returns `null` if UCI string is not valid.
  static Move? fromUci(String str) {
    if (str[1] == '@' && str.length == 4) {
      final role = Role.fromChar(str[0]);
      final to = parseSquare(str.substring(2));
      if (role != null && to != null) return DropMove(to: to, role: role);
    } else if (str.length == 4 || str.length == 5) {
      final from = parseSquare(str.substring(0, 2));
      final to = parseSquare(str.substring(2, 4));
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

  /// The origin square of this move.
  final Square from;

  /// The role of the promoted piece, if any.
  final Role? promotion;

  /// Gets UCI notation, like `g1f3` for a normal move, `a7a8q` for promotion to a queen.
  @override
  String get uci =>
      from.algebraicNotation +
      to.algebraicNotation +
      (promotion != null ? promotion!.letter : '');

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
  const DropMove({
    required super.to,
    required this.role,
  });

  final Role role;

  /// Gets UCI notation of the drop, like `Q@f7`.
  @override
  String get uci => '${role.uppercaseLetter}@${to.algebraicNotation}';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other.runtimeType == runtimeType && hashCode == other.hashCode;
  }

  @override
  int get hashCode => Object.hash(to, role);
}

@immutable
class FenError implements Exception {
  final String message;
  const FenError(this.message);
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

/// The white pawn piece kind.
const PieceKind kWhitePawnKind = (Side.white, Role.pawn);

/// The white knight piece kind.
const PieceKind kWhiteKnightKind = (Side.white, Role.knight);

/// The white bishop piece kind.
const PieceKind kWhiteBishopKind = (Side.white, Role.bishop);

/// The white rook piece kind.
const PieceKind kWhiteRookKind = (Side.white, Role.rook);

/// The white queen piece kind.
const PieceKind kWhiteQueenKind = (Side.white, Role.queen);

/// The white king piece kind.
const PieceKind kWhiteKingKind = (Side.white, Role.king);

/// The black pawn piece kind.
const PieceKind kBlackPawnKind = (Side.black, Role.pawn);

/// The black knight piece kind.
const PieceKind kBlackKnightKind = (Side.black, Role.knight);

/// The black bishop piece kind.
const PieceKind kBlackBishopKind = (Side.black, Role.bishop);

/// The black rook piece kind.
const PieceKind kBlackRookKind = (Side.black, Role.rook);

/// The black queen piece kind.
const PieceKind kBlackQueenKind = (Side.black, Role.queen);

/// The black king piece kind.
const PieceKind kBlackKingKind = (Side.black, Role.king);
