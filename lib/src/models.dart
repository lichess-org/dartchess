import 'package:meta/meta.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import './utils.dart';

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

/// A square of the chessboard.
///
/// Square values are between 0 and 63, representing the squares from a1 to h8.
enum Square {
  a1._(0),
  b1._(1),
  c1._(2),
  d1._(3),
  e1._(4),
  f1._(5),
  g1._(6),
  h1._(7),
  a2._(8),
  b2._(9),
  c2._(10),
  d2._(11),
  e2._(12),
  f2._(13),
  g2._(14),
  h2._(15),
  a3._(16),
  b3._(17),
  c3._(18),
  d3._(19),
  e3._(20),
  f3._(21),
  g3._(22),
  h3._(23),
  a4._(24),
  b4._(25),
  c4._(26),
  d4._(27),
  e4._(28),
  f4._(29),
  g4._(30),
  h4._(31),
  a5._(32),
  b5._(33),
  c5._(34),
  d5._(35),
  e5._(36),
  f5._(37),
  g5._(38),
  h5._(39),
  a6._(40),
  b6._(41),
  c6._(42),
  d6._(43),
  e6._(44),
  f6._(45),
  g6._(46),
  h6._(47),
  a7._(48),
  b7._(49),
  c7._(50),
  d7._(51),
  e7._(52),
  f7._(53),
  g7._(54),
  h7._(55),
  a8._(56),
  b8._(57),
  c8._(58),
  d8._(59),
  e8._(60),
  f8._(61),
  g8._(62),
  h8._(63);

  /// Constructs a [Square] from a value between 0 and 63.
  factory Square(int value) => switch (value) {
        0 => Square.a1,
        1 => Square.b1,
        2 => Square.c1,
        3 => Square.d1,
        4 => Square.e1,
        5 => Square.f1,
        6 => Square.g1,
        7 => Square.h1,
        8 => Square.a2,
        9 => Square.b2,
        10 => Square.c2,
        11 => Square.d2,
        12 => Square.e2,
        13 => Square.f2,
        14 => Square.g2,
        15 => Square.h2,
        16 => Square.a3,
        17 => Square.b3,
        18 => Square.c3,
        19 => Square.d3,
        20 => Square.e3,
        21 => Square.f3,
        22 => Square.g3,
        23 => Square.h3,
        24 => Square.a4,
        25 => Square.b4,
        26 => Square.c4,
        27 => Square.d4,
        28 => Square.e4,
        29 => Square.f4,
        30 => Square.g4,
        31 => Square.h4,
        32 => Square.a5,
        33 => Square.b5,
        34 => Square.c5,
        35 => Square.d5,
        36 => Square.e5,
        37 => Square.f5,
        38 => Square.g5,
        39 => Square.h5,
        40 => Square.a6,
        41 => Square.b6,
        42 => Square.c6,
        43 => Square.d6,
        44 => Square.e6,
        45 => Square.f6,
        46 => Square.g6,
        47 => Square.h6,
        48 => Square.a7,
        49 => Square.b7,
        50 => Square.c7,
        51 => Square.d7,
        52 => Square.e7,
        53 => Square.f7,
        54 => Square.g7,
        55 => Square.h7,
        56 => Square.a8,
        57 => Square.b8,
        58 => Square.c8,
        59 => Square.d8,
        60 => Square.e8,
        61 => Square.f8,
        62 => Square.g8,
        63 => Square.h8,
        int() => throw ArgumentError('Invalid square value: $value'),
      };

  /// Constructs a [Square] from an algebraic notation, such as 'a1', 'b2', etc.
  factory Square.fromAlgebraic(String algebraic) {
    final file = algebraic.codeUnitAt(0) - 97;
    final rank = algebraic.codeUnitAt(1) - 49;
    return Square(rank * 8 + file);
  }

  const Square._(this.value);

  bool operator <(Square other) => value < other.value;
  bool operator <=(Square other) => value <= other.value;
  bool operator >(Square other) => value > other.value;
  bool operator >=(Square other) => value >= other.value;

  /// Calculates the offset from a square index without checking for
  /// overflow.
  ///
  /// It is the callers responsibility to ensure that `delta` is a valid
  /// offset for this [Square].
  Square offset(int delta) {
    assert(delta >= -63 && delta <= 63);
    final newSquare = value + delta;
    if (newSquare < 0 || newSquare > 63) {
      throw RangeError('Invalid offset: $delta for square $this');
    }
    return Square(newSquare);
  }

  /// Return the bitwise XOR of the numeric square representation.
  Square xor(Square other) => Square(value ^ other.value);

  /// Number between 0 and 63 representing a square on the board.
  final int value;

  /// The file (0 based x-coordinate) of the square on the board.
  int get file => value & 0x7;

  /// The rank (0 based y-coordinate) of the square on the board.
  int get rank => value >> 3;

  /// The Algebraic Notation of the square, such as 'a1', 'b2', etc.
  String get algebraicNotation => name;

  /// The file of the square in Algebraic Notation, such as 'a', 'b', 'c', etc.
  String get algebraicFile => name[0];

  /// The rank of the square in Algebraic Notation, such as '1', '2', '3', etc.
  String get algebraicRank => name[1];
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
