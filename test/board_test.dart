import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';

void main() {
  test('empty board', () {
    expect(Board.empty().pieces.isEmpty, true);
    expect(Board.empty().pieceAt(0), null);
  });

  test('standard board', () {
    expect(Board.standard().pieces.length, 32);
  });

  test('setPieceAt', () {
    final board = Board.empty();
    final piece = Piece(color: Color.white, role: Role.king);
    board.setPieceAt(0, piece);
    expect(board.pieces.length, 1);
    expect(board.pieceAt(0), piece);
  });

  test('clone', () {
    final board = Board.standard();
    final clone = board.clone();
    expect(board, clone);
    expect(identical(board, clone), false);
    board.setPieceAt(24, Piece(color: Color.white, role: Role.queen));
    expect(board.pieces.length, 33);
    expect(clone.pieces.length, 32);
  });

  test('parse board fen', () {
    final board = Board.parseFen(kInitialBoardFEN);
    expect(board, Board.standard());
  });

  test('parse board fen, promoted piece', () {
    final board =
        Board.parseFen('rQ~q1kb1r/pp2pppp/2p5/8/3P1Bb1/4PN2/PPP3PP/R2QKB1R');
    expect(board.promoted.squares.length, 1);
  });

  test('invalid board fen', () {
    expect(
        () => Board.parseFen('4k2r/8/8/8/8/RR2K2R'),
        throwsA(predicate(
            (e) => e is InvalidFenException && e.message == 'ERR_BOARD')));

    expect(() => Board.parseFen('lol'),
        throwsA(TypeMatcher<InvalidFenException>()));
  });

  test('make board fen', () {
    expect(Board.empty().fen, kEmptyBoardFEN);
    expect(Board.standard().fen, kInitialBoardFEN);
  });
}
