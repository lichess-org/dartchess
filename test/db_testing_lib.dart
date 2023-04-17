import 'package:dartchess/dartchess.dart';

const verbosePrinting = false;
bool printedNotice = false;

void conditionalPrint(Object? a) {
  if (!printedNotice) {
    printedNotice = true;
    print('=' * 60);
    print('${'=\tVERBOSE PRINTING'.padRight(53)}=');
    if (verbosePrinting) {
      print('${'=\tverbosePrinting is ON'.padRight(53)}=');
      print('${'=\t'.padRight(53)}=');
      print('${'=\tTo disable, set the "verbosePrinting"'.padRight(53)}=');
      print('${'=\tconstant to false'.padRight(53)}=');
    } else {
      print('${'=\tverbosePrinting is OFF'.padRight(53)}=');
      print('${'=\t'.padRight(53)}=');
      print(
          '${'=\tSet the "verbosePrinting" constant to true to help'.padRight(53)}=');
      print('${'=\twith debugging these tests'.padRight(53)}=');
    }
    print('${'=\t(line 3 of \\test\\db_testing_lib.dart)'.padRight(53)}=');
    print('=' * 60);
  }
  if (verbosePrinting) {
    print(a);
  }
}

enum DropZone { none, whiteHomeRow, blackHomeRow, anywhere }

const noDrops = <int>[];
const whiteHomeRow = <int>[
  0,
  1,
  2,
  3,
  4,
  5,
  6,
  7,
];
const blackHomeRow = <int>[
  56,
  57,
  58,
  59,
  60,
  61,
  62,
  63,
];

class MyExpectations {
  final int legalDrops;
  final int legalMoves;
  final DropZone legalDropZone;
  final List<Role> rolesThatCanDrop;
  final List<Role> rolesThatCantDrop;

  const MyExpectations(
      {required this.legalMoves,
      required this.legalDrops,
      required this.legalDropZone,
      required this.rolesThatCanDrop,
      required this.rolesThatCantDrop});

  String testLegalMoves(List<Move> a) {
    if (a.whereType<NormalMove>().length != legalMoves) {
      return 'Expected $legalMoves legal moves, got ${a.whereType<NormalMove>().length}';
    }
    if (a.whereType<DropMove>().length != legalDrops) {
      return 'Expected $legalDrops legal drops, got ${a.whereType<DropMove>().length}';
    }
    for (final move in a) {
      if (move is DropMove) {
        if (rolesThatCantDrop.contains(move.role)) {
          return '${move.role} is listed in rolesThatCantDrop';
        }
        if (!rolesThatCanDrop.contains(move.role)) {
          return '${move.role} is not listed in rolesThatCanDrop';
        }
        if (legalDropZone == DropZone.anywhere &&
            move.role == Role.pawn &&
            (whiteHomeRow.contains(move.to) ||
                blackHomeRow.contains(move.to))) {
          return 'Drop zone is anywhere, but a pawn cannot be dropped in rows 1 or 8';
        } else if (legalDropZone == DropZone.whiteHomeRow &&
            !whiteHomeRow.contains(move.to)) {
          return 'Drop zone is whiteHomeRow, but ${move.to} is not in whiteHomeRow';
        } else if (legalDropZone == DropZone.blackHomeRow &&
            !blackHomeRow.contains(move.to)) {
          return 'Drop zone is blackHomeRow, but ${move.to} is not in whiteHomeRow';
        } else if (legalDropZone == DropZone.none &&
            !noDrops.contains(move.to)) {
          return 'Drop zone is none, but ${move.to} is not in noDrops';
        }
      }
    }
    return '';
  }
}

List<DropMove> dropTestEachSquare(Position position) {
  final legalDrops = <DropMove>[];
  final allRoles = <Role>[
    Role.pawn,
    Role.knight,
    Role.bishop,
    Role.rook,
    Role.queen,
    Role.king
  ];
  for (final pieceRole in allRoles) {
    for (int a = 0; a < 64; a++) {
      if (position.isLegal(DropMove(role: pieceRole, to: a))) {
        legalDrops.add(DropMove(role: pieceRole, to: a));
      }
    }
  }
  return legalDrops;
}

List<NormalMove> moveTestEachSquare(Position position) {
  final legalMoves = <NormalMove>[];
  for (int a = 0; a < 64; a++) {
    for (int b = 0; b < 64; b++) {
      if (position.isLegal(NormalMove(from: a, to: b))) {
        legalMoves.add(NormalMove(from: a, to: b));
      }
    }
  }
  return legalMoves;
}

List<Move> printBoard(Position a, {bool printLegalMoves = false}) {
  final z = StringBuffer();
  final y = StringBuffer();
  String x = '';
  int moves = 0;
  int drops = 0;

  final legalMoves = <Move>[];
  if (printLegalMoves) {
    for (final move in moveTestEachSquare(a)) {
      z.write('${move.uci}, ');
      legalMoves.add(move);
      moves++;
    }
    x = 'Legal Moves ($moves):\n$z\n';
    for (final drop in dropTestEachSquare(a)) {
      y.write('${drop.uci}, ');
      legalMoves.add(drop);
      drops++;
    }
    x += 'Legal Drops ($drops):\n$y';
  }

  conditionalPrint('${humanReadableBoard(a.board, a.pockets)}$x');
  conditionalPrint(
      '------------------------------------------------------------');
  return legalMoves;
}
