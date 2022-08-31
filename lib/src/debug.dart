import './square_set.dart';
import './board.dart';
import './models.dart';
import './position.dart';
import './utils.dart';

/// Takes a string like:
/// . 1 1 1 . . . .
/// . 1 . 1 . . . .
/// . 1 . . 1 . . .
/// . 1 . . . 1 . .
/// . 1 1 1 1 . . .
/// . 1 . . . 1 . .
/// . 1 . . . 1 . .
/// . 1 . . 1 . . .
///
/// and returns a SquareSet. Useful for debugging/testing purposes.
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
String printSquareSet(SquareSet sq) {
  String r = '';
  for (int y = 7; y >= 0; y--) {
    for (int x = 0; x < 8; x++) {
      final square = x + y * 8;
      r += (sq.has(square) ? '1' : '.');
      r += (x < 7 ? ' ' : '\n');
    }
  }
  return r;
}

/// Prints the board as a human readable string format
String printBoard(Board board) {
  String r = '';
  for (int y = 7; y >= 0; y--) {
    for (int x = 0; x < 8; x++) {
      final square = x + y * 8;
      final p = board.pieceAt(square);
      final col = p != null ? p.fenChar : '.';
      r += col;
      r += (x < 7 ? (col.length < 2 ? ' ' : '') : '\n');
    }
  }
  return r;
}

final _promotionRoles = [Role.queen, Role.rook, Role.knight, Role.bishop];

/// Counts legal move paths of a given length.
///
/// Computing perft numbers is useful for comparing, testing and debugging move
/// generation correctness and performance.
int perft(Position pos, int depth, {shouldLog = false}) {
  if (depth < 1) return 1;

  if (!shouldLog && depth == 1) {
    // Optimization for leaf nodes.
    int nodes = 0;
    for (final entry in pos.legalMoves.entries) {
      final from = entry.key;
      final to = entry.value;
      nodes += to.size;
      if (pos.board.pawns.has(from)) {
        final backrank = SquareSet.backrankOf(opposite(pos.turn));
        nodes += to.intersect(backrank).size * (_promotionRoles.length - 1);
      }
    }
    return nodes;
  } else {
    int nodes = 0;
    for (final entry in pos.legalMoves.entries) {
      final from = entry.key;
      final dests = entry.value;
      final promotions =
          squareRank(from) == (pos.turn == Color.white ? 6 : 1) &&
                  pos.board.pawns.has(from)
              ? _promotionRoles
              : [null];
      for (final to in dests.squares) {
        for (final promotion in promotions) {
          final move = Move(from: from, to: to, promotion: promotion);
          final child = pos.playUnchecked(move);
          final children = perft(child, depth - 1);
          if (shouldLog) print('${makeUci(move)} $children');
          nodes += children;
        }
      }
    }
    return nodes;
  }
}
