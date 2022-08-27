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

String makeSquare(Square square) =>
    kFileNames[squareFile(square)] + kRankNames[squareRank(square)];

/// Converts a move to UCI notation, like `g1f3` for a normal move,
/// `a7a8q` for promotion to a queen.
String makeUci(Move move) =>
    makeSquare(move.from) +
    makeSquare(move.to) +
    (move.promotion != null ? roleToChar(move.promotion!) : '');

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
