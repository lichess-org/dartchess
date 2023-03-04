import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';

void main() {
  test('implements hashCode/==', () {
    expect(Board.empty, Board.empty);
    expect(Board.standard, Board.standard);
    expect(Board.empty, isNot(Board.standard));
    expect(Board.standard, isNot(Board.empty));
    expect(Board.parseFen(kInitialBoardFEN), Board.standard);
  });

  test('empty board', () {
    expect(Board.empty.pieces.isEmpty, true);
    expect(Board.empty.pieceAt(0), null);
  });

  test('standard board', () {
    expect(Board.standard.pieces.length, 32);
  });

  test('setPieceAt', () {
    const piece = Piece.whiteKing;
    final board = Board.empty.setPieceAt(0, piece);
    expect(board.occupied, const SquareSet(0x0000000000000001));
    expect(board.pieces.length, 1);
    expect(board.pieceAt(0), piece);

    final board2 = Board.standard.setPieceAt(60, piece);
    expect(board2.pieceAt(60), piece);
    expect(board2.white, const SquareSet(0x100000000000FFFF));

    expect(board2.black, const SquareSet(0xEFFF000000000000));
    expect(board2.pawns, const SquareSet(0x00FF00000000FF00));
    expect(board2.knights, const SquareSet(0x4200000000000042));
    expect(board2.bishops, const SquareSet(0x2400000000000024));
    expect(board2.rooks, SquareSet.corners);
    expect(board2.queens, const SquareSet(0x0800000000000008));
    expect(board2.kings, const SquareSet(0x1000000000000010));
  });

  test('removePieceAt', () {
    final board = Board.empty.setPieceAt(10, Piece.whiteKing);
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
    expect(() => Board.parseFen('4k2r/8/8/8/8/RR2K2R'),
        throwsA(predicate((e) => e is FenError && e.message == 'ERR_BOARD')));

    expect(() => Board.parseFen('lol'), throwsA(const TypeMatcher<FenError>()));
  });

  test('make board fen', () {
    expect(Board.empty.fen, kEmptyBoardFEN);
    expect(Board.standard.fen, kInitialBoardFEN);
  });
}
