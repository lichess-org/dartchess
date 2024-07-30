import 'package:dartchess/dartchess.dart';

void main() {
  // Parse fen and create a valid chess position
  final setup = Setup.parseFen(
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
  final pos = Chess.fromSetup(setup);

  // Generate legal moves in algebraic notation
  final legalMoves = legalMovesOf(pos);

  assert(legalMoves[Square.e2]!.length == 2);

  const move = NormalMove(from: Square.e2, to: Square.e4);

  assert(pos.isLegal(move));

  // Play moves
  final pos2 = pos.play(move);

  // Detect game end conditions
  assert(pos2.isGameOver == false);
  assert(pos2.isCheckmate == false);
  assert(pos2.outcome == null);
  assert(pos2.isInsufficientMaterial == false);
}
