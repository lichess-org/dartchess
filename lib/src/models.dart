enum Color {
  white, black;

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

  String get kind => '${color.name}${role.name}';

  @override
  toString() {
    return kind;
  }

  @override
  bool operator ==(Object other) {
    return other.runtimeType == runtimeType && hashCode == other.hashCode;
  }

  @override
  int get hashCode => kind.hashCode;
}

class Tuple<T1, T2> {
  final T1 a;
  final T2 b;

  Tuple(this.a, this.b);
}
