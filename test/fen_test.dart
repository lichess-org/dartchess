import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';

void main() {
  test('parse board fen', () {
    final board = parseBoardFen(kInitialBoardFen);
    expect(board, Board.standard);
  });

  test('parse board fen, promoted piece', () {
    final board = parseBoardFen('rQ~q1kb1r/pp2pppp/2p5/8/3P1Bb1/4PN2/PPP3PP/R2QKB1R');
    expect(board.promoted.squares.length, 1);
  });

  test('parse castling fen, standard initial board', () {
    expect(parseCastlingFen(Board.standard, 'KQkq'), SquareSet.corners);
    expect(parseCastlingFen(Board.standard, '-'), SquareSet.empty);
  });
}
