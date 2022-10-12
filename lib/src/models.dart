import './utils.dart';

enum Side { white, black }

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

typedef BySide<T> = Map<Side, T>;
typedef ByRole<T> = Map<Role, T>;

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
      return Piece(role: role, color: ch.toLowerCase() == ch ? Side.black : Side.white);
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
  toString() {
    return '${color.name}${role.name}';
  }

  @override
  bool operator ==(Object other) {
    return other is Piece &&
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
abstract class Move {
  const Move({
    required this.to,
  });

  /// The target square of this move.
  final Square to;

  /// Gets the UCI notation of this move.
  String get uci;

  /// Constructs a [Move] from an UCI string.
  ///
  /// Throws an [ArgumentError] if the argument is not a valid UCI string.
  static Move fromUci(String str) {
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
          throw ArgumentError('Invalid UCI string');
        }
      }
      if (from != null && to != null) {
        return NormalMove(from: from, to: to, promotion: promotion);
      }
    }
    throw ArgumentError('Invalid UCI string');
  }
}

/// Represents a chess move, possibly a promotion.
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
      toAlgebraic(from) + toAlgebraic(to) + (promotion != null ? promotion!.char : '');

  @override
  bool operator ==(Object other) {
    return other.runtimeType == runtimeType && hashCode == other.hashCode;
  }

  @override
  int get hashCode => Object.hash(from, to, promotion);
}

/// Represents a drop move.
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
    return other.runtimeType == runtimeType && hashCode == other.hashCode;
  }

  @override
  int get hashCode => Object.hash(to, role);
}

/// Represents a 2-tuple, or pair.
class Tuple2<T1, T2> {
  /// First item of the tuple.
  final T1 item1;

  /// Second item of the tuple.
  final T2 item2;

  /// Creates a new tuple value with the specified items.
  const Tuple2(this.item1, this.item2);

  /// Returns a tuple with the first item set to the specified value.
  Tuple2<T1, T2> withItem1(T1 v) => Tuple2<T1, T2>(v, item2);

  /// Returns a tuple with the second item set to the specified value.
  Tuple2<T1, T2> withItem2(T2 v) => Tuple2<T1, T2>(item1, v);

  @override
  String toString() => '[$item1, $item2]';

  @override
  bool operator ==(Object other) => other is Tuple2 && item1 == other.item1 && item2 == other.item2;

  @override
  int get hashCode => Object.hash(item1, item2);
}

class FenError implements Exception {
  final String message;
  FenError(this.message);
}
