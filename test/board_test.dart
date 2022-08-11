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
}
