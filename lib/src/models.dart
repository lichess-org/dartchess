import './utils.dart';

enum Color {
  white,
  black;

  Color fromName(String name) {
    switch (name) {
      case 'white':
        return Color.white;
      case 'black':
        return Color.black;
      default:
        throw Exception('$name is not a valid color for Color');
    }
  }
}

enum Role { king, queen, knight, bishop, rook, pawn }

/// Number between 0 and 63 included representing a square on the board.
///
/// See [SquareSet] to see how the mapping looks like.
typedef Square = int;

typedef ByColor<T> = Map<Color, T>;
typedef ByRole<T> = Map<Role, T>;

class Piece {
  const Piece({
    required this.color,
    required this.role,
    this.promoted = false,
  });

  final Color color;
  final Role role;
  final bool promoted;

  String get fenChar {
    String r = roleToChar(role);
    if (color == Color.white) r = r.toUpperCase();
    if (promoted) r += '~';
    return r;
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
  bool operator ==(Object other) =>
      other is Tuple2 && item1 == other.item1 && item2 == other.item2;

  @override
  int get hashCode => Object.hash(item1, item2);
}

class FenError implements Exception {
  final String message;
  FenError(this.message);
}
