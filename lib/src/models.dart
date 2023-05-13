import 'package:meta/meta.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import './utils.dart';

enum Side {
  white,
  black;

  Side get opposite => this == Side.white ? Side.black : Side.white;
}

enum SquareColor {
  light,
  dark;

  SquareColor get opposite =>
      this == SquareColor.light ? SquareColor.dark : SquareColor.light;
}

enum CastlingSide {
  queen,
  king;
}

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

  String get char {
    switch (this) {
      case Role.pawn:
        return 'p';
      case Role.knight:
        return 'n';
      case Role.bishop:
        return 'b';
      case Role.rook:
        return 'r';
      case Role.queen:
        return 'q';
      case Role.king:
        return 'k';
    }
  }
}

/// Number between 0 and 63 included representing a square on the board.
///
/// See [SquareSet] to see how the mapping looks like.
typedef Square = int;

/// All the squares on the board.
abstract class Squares {
  static const a1 = 0;
  static const b1 = 1;
  static const c1 = 2;
  static const d1 = 3;
  static const e1 = 4;
  static const f1 = 5;
  static const g1 = 6;
  static const h1 = 7;
  static const a2 = 8;
  static const b2 = 9;
  static const c2 = 10;
  static const d2 = 11;
  static const e2 = 12;
  static const f2 = 13;
  static const g2 = 14;
  static const h2 = 15;
  static const a3 = 16;
  static const b3 = 17;
  static const c3 = 18;
  static const d3 = 19;
  static const e3 = 20;
  static const f3 = 21;
  static const g3 = 22;
  static const h3 = 23;
  static const a4 = 24;
  static const b4 = 25;
  static const c4 = 26;
  static const d4 = 27;
  static const e4 = 28;
  static const f4 = 29;
  static const g4 = 30;
  static const h4 = 31;
  static const a5 = 32;
  static const b5 = 33;
  static const c5 = 34;
  static const d5 = 35;
  static const e5 = 36;
  static const f5 = 37;
  static const g5 = 38;
  static const h5 = 39;
  static const a6 = 40;
  static const b6 = 41;
  static const c6 = 42;
  static const d6 = 43;
  static const e6 = 44;
  static const f6 = 45;
  static const g6 = 46;
  static const h6 = 47;
  static const a7 = 48;
  static const b7 = 49;
  static const c7 = 50;
  static const d7 = 51;
  static const e7 = 52;
  static const f7 = 53;
  static const g7 = 54;
  static const h7 = 55;
  static const a8 = 56;
  static const b8 = 57;
  static const c8 = 58;
  static const d8 = 59;
  static const e8 = 60;
  static const f8 = 61;
  static const g8 = 62;
  static const h8 = 63;
}

typedef BySide<T> = IMap<Side, T>;
typedef ByRole<T> = IMap<Role, T>;
typedef ByCastlingSide<T> = IMap<CastlingSide, T>;

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

  String get fenChar {
    String r = role.char;
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

/// Represents a chess move, possibly a promotion.
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
      toAlgebraic(from) +
      toAlgebraic(to) +
      (promotion != null ? promotion!.char : '');

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
  String get uci => '${role.char.toUpperCase()}@${toAlgebraic(to)}';

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
enum Rules {
  chess,
  antichess,
  kingofthehill,
  threecheck,
  atomic,
  horde,
  racingKings,
  crazyhouse;

  /// Parses a PGN header variant tag
  static Rules? fromPgn(String? variant) {
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
        return Rules.chess;
      case 'crazyhouse':
      case 'crazy house':
      case 'house':
      case 'zh':
        return Rules.crazyhouse;
      case 'king of the hill':
      case 'koth':
      case 'kingofthehill':
        return Rules.kingofthehill;
      case 'three-check':
      case 'three check':
      case 'threecheck':
      case 'three check chess':
      case '3-check':
      case '3 check':
      case '3check':
        return Rules.threecheck;
      case 'antichess':
      case 'anti chess':
      case 'anti':
        return Rules.antichess;
      case 'atomic':
      case 'atom':
      case 'atomic chess':
        return Rules.atomic;
      case 'horde':
      case 'horde chess':
        return Rules.horde;
      case 'racing kings':
      case 'racingkings':
      case 'racing':
      case 'race':
        return Rules.racingKings;
      default:
        return null;
    }
  }
}
