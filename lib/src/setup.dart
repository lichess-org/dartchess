import './square_set.dart';
import './models.dart';
import './board.dart';

/// A not necessarily legal position.
class Setup {
  final Board board;
  final Color turn;
  final SquareSet unmovedRooks;
  final int? epSquare;
  final int halfmoves;
  final int fullmoves;

  Setup({
    required this.board,
    required this.turn,
    required this.unmovedRooks,
    this.epSquare,
    required this.halfmoves,
    required this.fullmoves,
  });

  Setup.standard()
      : board = Board.standard(),
        turn = Color.white,
        unmovedRooks = SquareSet.corners,
        epSquare = null,
        halfmoves = 0,
        fullmoves = 1;
}
