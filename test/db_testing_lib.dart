import 'package:dartchess/dartchess.dart';

const verbosePrinting = true;

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

void conditionalPrint(Object? a) {
  if (verbosePrinting) print(a);
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
  final legalMoves = <Move>[];
  if (printLegalMoves) {
    z.write('Legal moves: ');
    for (final move in moveTestEachSquare(a)) {
      z.write('${move.uci}, ');
      legalMoves.add(move);
    }
    for (final drop in dropTestEachSquare(a)) {
      z.write('${drop.uci}, ');
      legalMoves.add(drop);
    }
  }

  conditionalPrint('${humanReadableBoard(a.board, a.pockets)}$z\n\n\n');
  return legalMoves;
}
