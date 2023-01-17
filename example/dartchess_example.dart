import 'package:dartchess/dartchess.dart';
import 'package:collection/collection.dart';

void main() {
  // Parse fen and create a valid chess position
  final setup = Setup.parseFen(
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
  final pos = Chess.fromSetup(setup);

  // Generate legal moves
  final legal = pos.legalMoves;

  // The total number of legal moves from the starting position is 20
  assert(legal.values.map((targets) => targets.size).sum == 20);

  // Play moves
  final pos2 = pos.play(const NormalMove(from: 12, to: 28));

  // Detect game end conditions
  assert(pos2.isGameOver == false);
  assert(pos2.isCheckmate == false);
  assert(pos2.outcome == null);
  assert(pos2.isInsufficientMaterial == false);
}
