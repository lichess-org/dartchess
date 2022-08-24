import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';

void main() {
  test('empty board', () {
    expect(Board.empty.pieces.isEmpty, true);
    expect(Board.empty.pieceAt(0), null);
  });

  test('standard board', () {
    expect(Board.standard.pieces.length, 32);
  });

  test('setPieceAt', () {
    final piece = Piece(color: Color.white, role: Role.king);
    final board = Board.empty.setPieceAt(0, piece);
    expect(board.pieces.length, 1);
    expect(board.pieceAt(0), piece);
  });

  test('removePieceAt', () {
    final piece = Piece(color: Color.white, role: Role.king);
    final board = Board.empty.setPieceAt(10, piece);
    expect(board.removePieceAt(10), Board.empty);
  });

  test('parse board fen', () {
    final board = Board.parseFen(kInitialBoardFEN);
    expect(board, Board.standard);
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
            (e) => e is FenError && e.message == 'ERR_BOARD')));

    expect(() => Board.parseFen('lol'),
        throwsA(TypeMatcher<FenError>()));
  });

  test('make board fen', () {
    expect(Board.empty.fen, kEmptyBoardFEN);
    expect(Board.standard.fen, kInitialBoardFEN);
  });
}
