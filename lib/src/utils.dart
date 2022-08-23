import './square_set.dart';
import './board.dart';
import './models.dart';
import './constants.dart';

Square squareRank(Square square) => square >> 3;
Square squareFile(Square square) => square & 0x7;

Square? parseSquare(String str) {
  if (str.length != 2) return null;
  final file = str.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = str.codeUnitAt(1) - '1'.codeUnitAt(0);
  if (file < 0 || file >= 8 || rank < 0 || rank >= 8) return null;
  return file + 8 * rank;
}

Color opposite(Color color) => color == Color.white ? Color.black : Color.white;

int? parseSmallUint(String str) =>
    RegExp(r'^\d{1,4}$').hasMatch(str) ? int.parse(str) : null;

String makeSquare(Square square) =>
    kFileNames[squareFile(square)] + kRankNames[squareRank(square)];

Role? charToRole(String ch) {
  switch (ch.toLowerCase()) {
    case 'p':
      return Role.pawn;
    case 'n':
      return Role.knight;
    case 'b':
      return Role.bishop;
    case 'r':
      return Role.rook;
    case 'q':
      return Role.queen;
    case 'k':
      return Role.king;
    default:
      return null;
  }
}

String roleToChar(Role role) {
  switch (role) {
    case Role.pawn:
      return 'p';
    case Role.knight:
      return 'n';
    case Role.bishop:
      return 'b';
    case Role.rook:
      return 'r';
    case Role.queen:
      return 'q';
    case Role.king:
      return 'k';
  }
}

/// Takes a string like:
/// . 1 1 1 . . . .
/// . 1 . 1 . . . .
/// . 1 . . 1 . . .
/// . 1 . . . 1 . .
/// . 1 1 1 1 . . .
/// . 1 . . . 1 . .
/// . 1 . . . 1 . .
/// . 1 . . 1 . . .
///
/// and returns a SquareSet. Useful for debugging/testing purposes.
SquareSet makeSquareSet(String rep) {
  SquareSet ret = SquareSet.empty;
  final table = rep
      .split('\n')
      .where((l) => l.isNotEmpty)
      .map((r) => r.split(' '))
      .toList()
      .reversed
      .toList();
  for (int y = 7; y >= 0; y--) {
    for (int x = 0; x < 8; x++) {
      final repSq = table[y][x];
      if (repSq == '1') {
        ret = ret.withSquare(x + y * 8);
      }
    }
  }
  return ret;
}

/// Prints the square set as a human readable string format
String printSquareSet(SquareSet sq) {
  String r = '';
  for (int y = 7; y >= 0; y--) {
    for (int x = 0; x < 8; x++) {
      final square = x + y * 8;
      r += (sq.has(square) ? '1' : '.');
      r += (x < 7 ? ' ' : '\n');
    }
  }
  return r;
}

/// Prints the board as a human readable string format
String printBoard(Board board) {
  String r = '';
  for (int y = 7; y >= 0; y--) {
    for (int x = 0; x < 8; x++) {
      final square = x + y * 8;
      final p = board.pieceAt(square);
      final col = p != null ? p.fenChar : '.';
      r += col;
      r += (x < 7 ? (col.length < 2 ? ' ' : '') : '\n');
    }
  }
  return r;
}
