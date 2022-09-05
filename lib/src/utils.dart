import './models.dart';
import './constants.dart';

/// Gets the rank of that square.
Square squareRank(Square square) => square >> 3;

/// Gets the file of that square.
Square squareFile(Square square) => square & 0x7;

/// Parses a string like 'a1', 'a2', etc. and returns a [Square] or `null` if the square
/// doesn't exist.
Square? parseSquare(String str) {
  if (str.length != 2) return null;
  final file = str.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = str.codeUnitAt(1) - '1'.codeUnitAt(0);
  if (file < 0 || file >= 8 || rank < 0 || rank >= 8) return null;
  return file + 8 * rank;
}

/// Returns the algebraic coordinate notation of the [Square].
String toAlgebraic(Square square) =>
    kFileNames[squareFile(square)] + kRankNames[squareRank(square)];

Color opposite(Color color) => color == Color.white ? Color.black : Color.white;
