const kFileNames = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
const kRankNames = ['1', '2', '3', '4', '5', '6', '7', '8'];

/// The board part of the initial position in the FEN format.
const kInitialBoardFEN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR';

/// Initial position in the Extended Position Description format.
const kInitialEPD = '$kInitialBoardFEN w KQkq -';

/// Initial position in the FEN format.
const kInitialFEN = '$kInitialEPD 0 1';

/// Empty board part in the FEN format.
const kEmptyBoardFEN = '8/8/8/8/8/8/8/8';

/// Empty board in the EPD format.
const kEmptyEPD = '$kEmptyBoardFEN w - -';

/// Empty board in the FEN format.
const kEmptyFEN = '$kEmptyEPD 0 1';
