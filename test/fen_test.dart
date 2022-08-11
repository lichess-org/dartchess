import 'package:dartchess/dartchess.dart';
import 'package:dartchess/src/utils.dart';
import 'package:test/test.dart';

void main() {
  test('parse board fen', () {
    final board = parseBoardFen(kInitialBoardFEN);
    expect(board, Board.standard());
  });

  test('parse board fen, promoted piece', () {
    final board =
        parseBoardFen('rQ~q1kb1r/pp2pppp/2p5/8/3P1Bb1/4PN2/PPP3PP/R2QKB1R');
    expect(board.promoted.squares.length, 1);
  });

  test('invalid board fen', () {
    expect(
        () => parseBoardFen('4k2r/8/8/8/8/RR2K2R'),
        throwsA(predicate(
            (e) => e is InvalidFenException && e.message == 'ERR_BOARD')));

    expect(() => parseBoardFen('lol'),
        throwsA(TypeMatcher<InvalidFenException>()));
  });

  test('parse castling fen, standard initial board', () {
    expect(parseCastlingFen(Board.standard(), 'KQkq'), SquareSet.corners);
    expect(parseCastlingFen(Board.standard(), '-'), SquareSet.empty);
  });

  test('parse castling fen, shredder notation', () {
    expect(parseCastlingFen(Board.standard(), 'HAha'), SquareSet.corners);
  });

  test('invalid castling fen', () {
    expect(
        () => parseCastlingFen(Board.standard(), 'BGL'),
        throwsA(predicate(
            (e) => e is InvalidFenException && e.message == 'ERR_CASTLING')));
  });

  test('parse initial fen', () {
    final setup = parseFen(kInitialFEN);
    expect(setup.board, Board.standard());
    expect(setup.turn, Color.white);
    expect(setup.unmovedRooks, SquareSet.corners);
    expect(setup.epSquare, null);
    expect(setup.halfmoves, 0);
    expect(setup.fullmoves, 1);
  });

  test('parse partial fen', () {
    final setup = parseFen(kInitialBoardFEN);
    expect(setup.board, Board.standard());
    expect(setup.turn, Color.white);
    expect(setup.unmovedRooks, SquareSet.empty);
    expect(setup.epSquare, null);
    expect(setup.halfmoves, 0);
    expect(setup.fullmoves, 1);
  });

  test('parse invalid fen', () {
    expect(() => parseFen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQQKBNR w cq - 0P1'), throwsException);
    expect(() => parseFen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w  - 0 1'), throwsException);
    expect(() => parseFen('4k2r/8/8/8/8/8/8/RR2K2R w KBQk - 0 1'), throwsException);
  });
}
