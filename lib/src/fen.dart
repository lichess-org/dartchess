import './board.dart';
import './models.dart';

class InvalidFenException implements Exception {
  String cause;
  InvalidFenException(this.cause);
}

String kInitialBoardFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR';

Board parseBoardFen(String boardFen) {
  final board = Board.empty;
  int rank = 7, file = 0;
  for (int i = 0; i < boardFen.length; i++) {
    final c = boardFen[i];
    if (c == '/' && file == 8) {
      file = 0;
      rank--;
    } else {
      final code = c.codeUnitAt(0);
      if (code < 57) {
        file += code - 48;
      } else {
        if (file >= 8 || rank < 0) throw InvalidFenException('ERR_BOARD');
        final square = file + rank * 8;
        final promoted = i + 1 < boardFen.length && boardFen[i + 1] == '~';
        final piece = _charToPiece(c, promoted);
        if (piece == null) throw InvalidFenException('ERR_BOARD');
        if (promoted) i++;
        board.setPieceAt(square, piece);
        file++;
      }
    }
  }
  if (rank != 0 || file != 8) throw InvalidFenException('BOARD_ERR');
  return board;
}

Piece? _charToPiece(String ch, bool promoted) {
  final roleLetter = ch.toLowerCase();
  final role = _roles[roleLetter];
  if (role != null) {
    return Piece(
        role: role,
        color: ch == roleLetter ? Color.black : Color.white,
        promoted: promoted);
  }
  return null;
}

const _roles = {
  'p': Role.pawn,
  'r': Role.rook,
  'n': Role.knight,
  'b': Role.bishop,
  'q': Role.queen,
  'k': Role.king,
};
