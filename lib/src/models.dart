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

class Tuple<T1, T2> {
  final T1 a;
  final T2 b;

  Tuple(this.a, this.b);
}

class InvalidFenException implements Exception {
  final String message;
  InvalidFenException(this.message);
}
