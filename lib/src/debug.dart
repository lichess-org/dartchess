import './board.dart';
import './models.dart';
import './position.dart';
import './square_set.dart';
import './utils.dart';

/// Takes a string and returns a SquareSet. Useful for debugging/testing purposes.
///
/// Example:
/// ```dart
/// final str = '''
/// . 1 1 1 . . . .
/// . 1 . 1 . . . .
/// . 1 . . 1 . . .
/// . 1 . . . 1 . .
/// . 1 1 1 1 . . .
/// . 1 . . . 1 . .
/// . 1 . . . 1 . .
/// . 1 . . 1 . . .
/// '''
/// final squareSet = makeSquareSet(str);
/// // SquareSet(0x0E0A12221E222212)
/// ```
SquareSet makeSquareSet(String rep) {
  SquareSet ret = SquareSet.empty;
  final table = rep
      .split('\n')
      .where((l) => l.isNotEmpty)
      .map((r) => r.split(' '))
      .toList()
      .reversed
      .toList();
  for (int y = 7; y >= 0; y--) {
    for (int x = 0; x < 8; x++) {
      final repSq = table[y][x];
      if (repSq == '1') {
        ret = ret.withSquare(x + y * 8);
      }
    }
  }
  return ret;
}

/// Prints the square set as a human readable string format
String humanReadableSquareSet(SquareSet sq) {
  final buffer = StringBuffer();
  for (int y = 7; y >= 0; y--) {
    for (int x = 0; x < 8; x++) {
      final square = x + y * 8;
      buffer.write(sq.has(square) ? '1' : '.');
      buffer.write(x < 7 ? ' ' : '\n');
    }
  }
  return buffer.toString();
}

/// Prints the board as a human readable string format
String humanReadableBoard(Board board) {
  final buffer = StringBuffer();
  for (int y = 7; y >= 0; y--) {
    for (int x = 0; x < 8; x++) {
      final square = x + y * 8;
      final p = board.pieceAt(square);
      final col = p != null ? p.fenChar : '.';
      buffer.write(col);
      buffer.write(x < 7 ? (col.length < 2 ? ' ' : '') : '\n');
    }
  }
  return buffer.toString();
}

final _promotionRoles = [Role.queen, Role.rook, Role.knight, Role.bishop];

/// Counts legal move paths of a given length.
///
/// Computing perft numbers is useful for comparing, testing and debugging move
/// generation correctness and performance.
int perft(Position pos, int depth, {bool shouldLog = false}) {
  if (depth < 1) return 1;

  final promotionRoles =
      pos is Antichess ? [..._promotionRoles, Role.king] : _promotionRoles;
  final legalDrops = pos.legalDrops;

  if (!shouldLog && depth == 1 && legalDrops.isEmpty) {
    // Optimization for leaf nodes.
    int nodes = 0;
    for (final entry in pos.legalMoves.entries) {
      final from = entry.key;
      final to = entry.value;
      nodes += to.size;
      if (pos.board.pawns.has(from)) {
        final backrank = SquareSet.backrankOf(pos.turn.opposite);
        nodes += to.intersect(backrank).size * (promotionRoles.length - 1);
      }
    }
    return nodes;
  } else {
    int nodes = 0;
    for (final entry in pos.legalMoves.entries) {
      final from = entry.key;
      final dests = entry.value;
      final promotions = squareRank(from) == (pos.turn == Side.white ? 6 : 1) &&
              pos.board.pawns.has(from)
          ? promotionRoles
          : [null];
      for (final to in dests.squares) {
        for (final promotion in promotions) {
          final move = NormalMove(from: from, to: to, promotion: promotion);
          final child = pos.playUnchecked(move);
          final children = perft(child, depth - 1);
          if (shouldLog) print('${move.uci} $children');
          nodes += children;
        }
      }
    }
    if (pos.pockets != null) {
      for (final role in Role.values) {
        if (pos.pockets!.of(pos.turn, role) > 0) {
          for (final to in (role == Role.pawn
                  ? legalDrops.diff(SquareSet.backranks)
                  : legalDrops)
              .squares) {
            final drop = DropMove(role: role, to: to);
            final child = pos.playUnchecked(drop);
            final children = perft(child, depth - 1);
            if (shouldLog) print('${drop.uci} $children');
            nodes += children;
          }
        }
      }
    }
    return nodes;
  }
}
