import 'package:meta/meta.dart';
import 'dart:math' as math;
import './constants.dart';
import './square_set.dart';
import './attacks.dart';
import './models.dart';
import './board.dart';
import './setup.dart';
import './utils.dart';

/// A base class for playable chess or chess variant positions.
///
/// See [Chess] for a concrete implementation of standard rules.
@immutable
abstract class Position<T extends Position<T>> {
  const Position({
    required this.board,
    this.pockets,
    required this.turn,
    required this.castles,
    this.epSquare,
    required this.halfmoves,
    required this.fullmoves,
  });

  /// Piece positions on the board.
  final Board board;

  /// Pockets in chess variants like [Crazyhouse].
  final Pockets? pockets;

  /// Side to move.
  final Side turn;

  /// Castling paths and unmoved rooks.
  final Castles castles;

  /// En passant target square.
  final Square? epSquare;

  /// Number of half-moves since the last capture or pawn move.
  final int halfmoves;

  /// Current move number.
  final int fullmoves;

  /// Abstract const constructor to be used by subclasses.
  const Position._initial()
      : board = Board.standard,
        pockets = null,
        turn = Side.white,
        castles = Castles.standard,
        epSquare = null,
        halfmoves = 0,
        fullmoves = 1;

  Position._fromSetupUnchecked(Setup setup)
      : board = setup.board,
        pockets = setup.pockets,
        turn = setup.turn,
        castles = Castles.fromSetup(setup),
        epSquare = _validEpSquare(setup),
        halfmoves = setup.halfmoves,
        fullmoves = setup.fullmoves;

  Position<T> _copyWith({
    Board? board,
    Pockets? pockets,
    Side? turn,
    Castles? castles,
    Square? epSquare,
    int? halfmoves,
    int? fullmoves,
  });

  Variant get variant => Variant.chess;

  /// Checks if the game is over due to a special variant end condition.
  bool get isVariantEnd;

  /// Tests special variant winning, losing and drawing conditions.
  Outcome? get variantOutcome;

  /// Gets the FEN string of this position.
  ///
  /// Contrary to the FEN given by [Setup], this should always be a legal
  /// position.
  String get fen {
    return Setup(
      board: board,
      pockets: pockets,
      turn: turn,
      unmovedRooks: castles.unmovedRooks,
      epSquare: _legalEpSquare(),
      halfmoves: halfmoves,
      fullmoves: fullmoves,
    ).fen;
  }

  /// Tests if the king is in check.
  bool get isCheck {
    final king = board.kingOf(turn);
    return king != null && checkers.isNotEmpty;
  }

  /// Tests if the game is over.
  bool get isGameOver =>
      isVariantEnd || isInsufficientMaterial || !hasSomeLegalMoves;

  /// Tests for checkmate.
  bool get isCheckmate =>
      !isVariantEnd && checkers.isNotEmpty && !hasSomeLegalMoves;

  /// Tests for stalemate.
  bool get isStalemate =>
      !isVariantEnd && checkers.isEmpty && !hasSomeLegalMoves;

  /// The outcome of the game, or `null` if the game is not over.
  Outcome? get outcome {
    if (variantOutcome != null) {
      return variantOutcome;
    } else if (isCheckmate) {
      return Outcome(winner: opposite(turn));
    } else if (isInsufficientMaterial || isStalemate) {
      return Outcome.draw;
    } else {
      return null;
    }
  }

  /// Tests if both [Side] have insufficient winning material.
  bool get isInsufficientMaterial =>
      Side.values.every((side) => hasInsufficientMaterial(side));

  /// Tests if the position has at least one legal move.
  bool get hasSomeLegalMoves {
    final context = _makeContext();
    for (final square in board.bySide(turn).squares) {
      if (_legalMovesOf(square, context: context).isNotEmpty) return true;
    }
    return false;
  }

  /// Gets all the legal moves of this position.
  Map<Square, SquareSet> get legalMoves {
    final context = _makeContext();
    if (context.isVariantEnd) return Map.unmodifiable({});
    return Map.unmodifiable({
      for (final s in board.bySide(turn).squares)
        s: _legalMovesOf(s, context: context)
    });
  }

  /// Gets all the legal drops of this position.
  SquareSet get legalDrops => SquareSet.empty;

  /// SquareSet of pieces giving check.
  SquareSet get checkers {
    final king = board.kingOf(turn);
    return king != null ? kingAttackers(king, opposite(turn)) : SquareSet.empty;
  }

  /// Attacks that a king on `square` would have to deal with.
  SquareSet kingAttackers(Square square, Side attacker, {SquareSet? occupied}) {
    return board.attacksTo(square, attacker, occupied: occupied);
  }

  /// Tests if a [Side] has insufficient winning material.
  bool hasInsufficientMaterial(Side side) {
    if (board.bySide(side).isIntersected(board.pawns | board.rooksAndQueens)) {
      return false;
    }
    if (board.bySide(side).isIntersected(board.knights)) {
      return board.bySide(side).size <= 2 &&
          board
              .bySide(opposite(side))
              .diff(board.kings)
              .diff(board.queens)
              .isEmpty;
    }
    if (board.bySide(side).isIntersected(board.bishops)) {
      final sameColor = !board.bishops.isIntersected(SquareSet.darkSquares) ||
          !board.bishops.isIntersected(SquareSet.lightSquares);
      return sameColor && board.pawns.isEmpty && board.knights.isEmpty;
    }
    return true;
  }

  /// Tests a move for legality.
  bool isLegal(Move move) {
    assert(move is NormalMove || move is DropMove);
    if (move is NormalMove) {
      if (move.promotion == Role.pawn) return false;
      if (move.promotion == Role.king) return false;
      if (move.promotion != null &&
          (!board.pawns.has(move.from) || !SquareSet.backranks.has(move.to))) {
        return false;
      }
      final legalMoves = _legalMovesOf(move.from);
      return legalMoves.has(move.to) || legalMoves.has(normalizeMove(move).to);
    } else if (move is DropMove) {
      if (pockets == null || pockets!.of(turn, move.role) <= 0) {
        return false;
      }
      if (move.role == Role.pawn && SquareSet.backranks.has(move.to)) {
        return false;
      }
      return legalDrops.has(move.to);
    }
    return false;
  }

  /// Gets the legal moves for that [Square].
  SquareSet legalMovesOf(Square square) {
    return _legalMovesOf(square);
  }

  /// Returns the Standard Algebraic Notation of this [Move] from the current [Position].
  String toSan(Move move) {
    final san = _makeSanWithoutSuffix(move);
    final newPos = playUnchecked(move);
    if (newPos.outcome?.winner != null) return '$san#';
    if (newPos.isCheck) return '$san+';
    return san;
  }

  /// Plays a move and returns the SAN representation of the [Move] from the [Position].
  ///
  /// Throws a [PlayError] if the move is not legal.
  Tuple2<Position<T>, String> playToSan(Move move) {
    if (isLegal(move)) {
      final san = _makeSanWithoutSuffix(move);
      final newPos = playUnchecked(move);
      final suffixed = newPos.outcome?.winner != null
          ? '$san#'
          : newPos.isCheck
              ? '$san+'
              : san;
      return Tuple2(newPos, suffixed);
    } else {
      throw const PlayError('Invalid move');
    }
  }

  /// Plays a move.
  ///
  /// Throws a [PlayError] if the move is not legal.
  Position<T> play(Move move) {
    if (isLegal(move)) {
      return playUnchecked(move);
    } else {
      throw const PlayError('Invalid move');
    }
  }

  /// Plays a move without checking if the move is legal.
  Position<T> playUnchecked(Move move) {
    assert(move is NormalMove || move is DropMove);
    if (move is NormalMove) {
      final piece = board.pieceAt(move.from);
      if (piece == null) {
        return _copyWith();
      }
      final castlingSide = _getCastlingSide(move);
      final epCaptureTarget = move.to + (turn == Side.white ? -8 : 8);
      Square? newEpSquare;
      Board newBoard = board.removePieceAt(move.from);
      Castles newCastles = castles;
      if (piece.role == Role.pawn) {
        if (move.to == epSquare) {
          newBoard = newBoard.removePieceAt(epCaptureTarget);
        }
        final delta = move.from - move.to;
        if (delta.abs() == 16 && move.from >= 8 && move.from <= 55) {
          newEpSquare = (move.from + move.to) >>> 1;
        }
      } else if (piece.role == Role.rook) {
        newCastles = newCastles.discardRookAt(move.from);
      } else if (piece.role == Role.king) {
        if (castlingSide != null) {
          final rookFrom = castles.rookOf(turn, castlingSide);
          if (rookFrom != null) {
            final rook = board.pieceAt(rookFrom);
            newBoard = newBoard
                .removePieceAt(rookFrom)
                .setPieceAt(_kingCastlesTo(turn, castlingSide), piece);
            if (rook != null) {
              newBoard =
                  newBoard.setPieceAt(_rookCastlesTo(turn, castlingSide), rook);
            }
          }
        }
        newCastles = newCastles.discardSide(turn);
      }

      if (castlingSide == null) {
        final newPiece = move.promotion != null
            ? piece.copyWith(role: move.promotion, promoted: pockets != null)
            : piece;
        newBoard = newBoard.setPieceAt(move.to, newPiece);
      }

      final capturedPiece = castlingSide == null
          ? board.pieceAt(move.to)
          : move.to == epSquare
              ? board.pieceAt(epCaptureTarget)
              : null;
      final isCapture = capturedPiece != null;

      if (capturedPiece != null && capturedPiece.role == Role.rook) {
        newCastles = newCastles.discardRookAt(move.to);
      }

      return _copyWith(
        halfmoves: isCapture || piece.role == Role.pawn ? 0 : halfmoves + 1,
        fullmoves: turn == Side.black ? fullmoves + 1 : fullmoves,
        pockets: capturedPiece != null
            ? pockets?.increment(opposite(capturedPiece.color),
                capturedPiece.promoted ? Role.pawn : capturedPiece.role)
            : pockets,
        board: newBoard,
        turn: opposite(turn),
        castles: newCastles,
        epSquare: newEpSquare,
      );
    } else if (move is DropMove) {
      return _copyWith(
        halfmoves: move.role == Role.pawn ? 0 : halfmoves + 1,
        fullmoves: turn == Side.black ? fullmoves + 1 : fullmoves,
        turn: opposite(turn),
        board: board.setPieceAt(move.to, Piece(color: turn, role: move.role)),
        pockets: pockets?.decrement(turn, move.role),
      );
    }
    return this;
  }

  /// Returns the normalized form of a [NormalMove] to avoid castling inconsistencies.
  Move normalizeMove(NormalMove move) {
    final side = _getCastlingSide(move);
    if (side == null) return move;
    final castlingRook = castles.rookOf(turn, side);
    return NormalMove(
      from: move.from,
      to: castlingRook ?? move.to,
    );
  }

  /// Checks the legality of this position.
  ///
  /// Throws a [PositionError] if it does not meet basic validity requirements.
  void validate({bool? ignoreImpossibleCheck}) {
    if (board.occupied.isEmpty) {
      throw PositionError.empty;
    }
    if (board.kings.size != 2) {
      throw PositionError.kings;
    }
    final ourKing = board.kingOf(turn);
    if (ourKing == null) {
      throw PositionError.kings;
    }
    final otherKing = board.kingOf(opposite(turn));
    if (otherKing == null) {
      throw PositionError.kings;
    }
    if (kingAttackers(otherKing, turn).isNotEmpty) {
      throw PositionError.oppositeCheck;
    }
    if (SquareSet.backranks.isIntersected(board.pawns)) {
      throw PositionError.pawnsOnBackrank;
    }
    final skipImpossibleCheck = ignoreImpossibleCheck ?? false;
    if (!skipImpossibleCheck) {
      _validateCheckers(ourKing);
    }
  }

  /// Checks if checkers are legal in this position.
  ///
  /// Throws a [PositionError.impossibleCheck] if it does not meet validity
  /// requirements.
  void _validateCheckers(Square ourKing) {
    final checkers = kingAttackers(ourKing, opposite(turn));
    if (checkers.isNotEmpty) {
      if (epSquare != null) {
        // The pushed pawn must be the only checker, or it has uncovered
        // check by a single sliding piece.
        final pushedTo = epSquare! ^ 8;
        final pushedFrom = epSquare! ^ 24;
        if (checkers.moreThanOne ||
            (checkers.first != pushedTo &&
                board
                    .attacksTo(ourKing, opposite(turn),
                        occupied: board.occupied
                            .withoutSquare(pushedTo)
                            .withSquare(pushedFrom))
                    .isNotEmpty)) {
          throw PositionError.impossibleCheck;
        }
      } else {
        // Multiple sliding checkers aligned with king.
        if (checkers.size > 2 ||
            (checkers.size == 2 &&
                ray(checkers.first!, checkers.last!).has(ourKing))) {
          throw PositionError.impossibleCheck;
        }
      }
    }
  }

  String _makeSanWithoutSuffix(Move move) {
    assert(move is NormalMove || move is DropMove);
    String san = '';
    if (move is NormalMove) {
      final role = board.roleAt(move.from);
      if (role == null) return '--';
      if (role == Role.king &&
          (board.bySide(turn).has(move.to) ||
              (move.to - move.from).abs() == 2)) {
        san = move.to > move.from ? 'O-O' : 'O-O-O';
      } else {
        final capture = board.occupied.has(move.to) ||
            (role == Role.pawn && squareFile(move.from) != squareFile(move.to));
        if (role != Role.pawn) {
          san = role.char.toUpperCase();

          // Disambiguation
          SquareSet others;
          if (role == Role.king) {
            others = kingAttacks(move.to) & board.kings;
          } else if (role == Role.queen) {
            others = queenAttacks(move.to, board.occupied) & board.queens;
          } else if (role == Role.rook) {
            others = rookAttacks(move.to, board.occupied) & board.rooks;
          } else if (role == Role.bishop) {
            others = bishopAttacks(move.to, board.occupied) & board.bishops;
          } else {
            others = knightAttacks(move.to) & board.knights;
          }
          others =
              others.intersect(board.bySide(turn)).withoutSquare(move.from);

          if (others.isNotEmpty) {
            final ctx = _makeContext();
            for (final from in others.squares) {
              if (!_legalMovesOf(from, context: ctx).has(move.to)) {
                others = others.withoutSquare(from);
              }
            }
            if (others.isNotEmpty) {
              bool row = false;
              bool column = others
                  .isIntersected(SquareSet.fromRank(squareRank(move.from)));
              if (others
                  .isIntersected(SquareSet.fromFile(squareFile(move.from)))) {
                row = true;
              } else {
                column = true;
              }
              if (column) {
                san += kFileNames[squareFile(move.from)];
              }
              if (row) {
                san += kRankNames[squareRank(move.from)];
              }
            }
          }
        } else if (capture) {
          san = kFileNames[squareFile(move.from)];
        }

        if (capture) san += 'x';
        san += toAlgebraic(move.to);
        if (move.promotion != null) {
          san += '=${move.promotion!.char.toUpperCase()}';
        }
      }
    } else {
      move as DropMove;
      if (move.role != Role.pawn) san = move.role.char.toUpperCase();
      san += '@${toAlgebraic(move.to)}';
    }
    return san;
  }

  /// Gets the legal moves for that [Square].
  ///
  /// Optionnaly pass a [_Context] of the position, to optimize performance when
  /// calling this method several times.
  SquareSet _legalMovesOf(Square square, {_Context? context}) {
    final ctx = context ?? _makeContext();
    if (ctx.isVariantEnd) return SquareSet.empty;
    final piece = board.pieceAt(square);
    if (piece == null || piece.color != turn) return SquareSet.empty;
    final king = ctx.king;
    if (king == null) return SquareSet.empty;

    SquareSet pseudo;
    SquareSet? legalEpSquare;
    if (piece.role == Role.pawn) {
      pseudo = pawnAttacks(turn, square) & board.bySide(opposite(turn));
      final delta = turn == Side.white ? 8 : -8;
      final step = square + delta;
      if (0 <= step && step < 64 && !board.occupied.has(step)) {
        pseudo = pseudo.withSquare(step);
        final canDoubleStep =
            turn == Side.white ? square < 16 : square >= 64 - 16;
        final doubleStep = step + delta;
        if (canDoubleStep && !board.occupied.has(doubleStep)) {
          pseudo = pseudo.withSquare(doubleStep);
        }
      }
      if (epSquare != null && _canCaptureEp(square)) {
        final pawn = epSquare! - delta;
        if (ctx.checkers.isEmpty || ctx.checkers.singleSquare == pawn) {
          legalEpSquare = SquareSet.fromSquare(epSquare!);
        }
      }
    } else if (piece.role == Role.bishop) {
      pseudo = bishopAttacks(square, board.occupied);
    } else if (piece.role == Role.knight) {
      pseudo = knightAttacks(square);
    } else if (piece.role == Role.rook) {
      pseudo = rookAttacks(square, board.occupied);
    } else if (piece.role == Role.queen) {
      pseudo = queenAttacks(square, board.occupied);
    } else {
      pseudo = kingAttacks(square);
    }

    pseudo = pseudo.diff(board.bySide(turn));

    if (piece.role == Role.king) {
      final occ = board.occupied.withoutSquare(square);
      for (final to in pseudo.squares) {
        if (kingAttackers(to, opposite(turn), occupied: occ).isNotEmpty) {
          pseudo = pseudo.withoutSquare(to);
        }
      }
      return pseudo
          .union(_castlingMove(CastlingSide.queen, ctx))
          .union(_castlingMove(CastlingSide.king, ctx));
    }

    if (ctx.checkers.isNotEmpty) {
      final checker = ctx.checkers.singleSquare;
      if (checker == null) return SquareSet.empty;
      pseudo = pseudo & between(checker, king).withSquare(checker);
    }

    if (ctx.blockers.has(square)) {
      pseudo = pseudo & ray(square, king);
    }

    if (legalEpSquare != null) {
      pseudo = pseudo | legalEpSquare;
    }

    return pseudo;
  }

  _Context _makeContext() {
    final king = board.kingOf(turn);
    if (king == null) {
      return _Context(
          isVariantEnd: isVariantEnd,
          mustCapture: false,
          king: king,
          blockers: SquareSet.empty,
          checkers: SquareSet.empty);
    }
    return _Context(
      isVariantEnd: isVariantEnd,
      mustCapture: false,
      king: king,
      blockers: _sliderBlockers(king),
      checkers: checkers,
    );
  }

  SquareSet _sliderBlockers(Square king) {
    final snipers = rookAttacks(king, SquareSet.empty)
        .intersect(board.rooksAndQueens)
        .union(bishopAttacks(king, SquareSet.empty)
            .intersect(board.bishopsAndQueens))
        .intersect(board.bySide(opposite(turn)));
    SquareSet blockers = SquareSet.empty;
    for (final sniper in snipers.squares) {
      final b = between(king, sniper) & board.occupied;
      if (!b.moreThanOne) blockers = blockers | b;
    }
    return blockers;
  }

  SquareSet _castlingMove(CastlingSide side, _Context context) {
    final king = context.king;
    if (king == null || context.checkers.isNotEmpty) {
      return SquareSet.empty;
    }
    final rook = castles.rookOf(turn, side);
    if (rook == null) return SquareSet.empty;
    if (castles.pathOf(turn, side).isIntersected(board.occupied)) {
      return SquareSet.empty;
    }

    final kingTo = _kingCastlesTo(turn, side);
    final kingPath = between(king, kingTo);
    final occ = board.occupied.withoutSquare(king);
    for (final sq in kingPath.squares) {
      if (kingAttackers(sq, opposite(turn), occupied: occ).isNotEmpty) {
        return SquareSet.empty;
      }
    }
    final rookTo = _rookCastlesTo(turn, side);
    final after = board.occupied
        .toggleSquare(king)
        .toggleSquare(rook)
        .toggleSquare(rookTo);
    if (kingAttackers(kingTo, opposite(turn), occupied: after).isNotEmpty) {
      return SquareSet.empty;
    }
    return SquareSet.fromSquare(rook);
  }

  bool _canCaptureEp(Square pawn) {
    if (epSquare == null) return false;
    if (!pawnAttacks(turn, pawn).has(epSquare!)) return false;
    final king = board.kingOf(turn);
    if (king == null) return true;
    final captured = epSquare! + (turn == Side.white ? -8 : 8);
    final occupied = board.occupied
        .toggleSquare(pawn)
        .toggleSquare(epSquare!)
        .toggleSquare(captured);
    return !board
        .attacksTo(king, opposite(turn), occupied: occupied)
        .isIntersected(occupied);
  }

  /// Detects if a move is a castling move.
  ///
  /// Returns the [CastlingSide] or `null` if the move is a regular move.
  CastlingSide? _getCastlingSide(Move move) {
    if (move is NormalMove) {
      final delta = move.to - move.from;
      if (delta.abs() != 2 && !board.bySide(turn).has(move.to)) {
        return null;
      }
      if (!board.kings.has(move.from)) {
        return null;
      }
      return delta > 0 ? CastlingSide.king : CastlingSide.queen;
    }
    return null;
  }

  Square? _legalEpSquare() {
    if (epSquare == null) return null;
    final ourPawns = board.piecesOf(turn, Role.pawn);
    final candidates = ourPawns & pawnAttacks(opposite(turn), epSquare!);
    for (final candidate in candidates.squares) {
      if (_legalMovesOf(candidate).has(epSquare!)) {
        return epSquare;
      }
    }
    return null;
  }
}

/// A standard chess position.
@immutable
class Chess extends Position<Chess> {
  const Chess({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
  });

  Chess._fromSetupUnchecked(super.setup) : super._fromSetupUnchecked();
  const Chess._initial() : super._initial();

  static const initial = Chess._initial();

  @override
  bool get isVariantEnd => false;

  @override
  Outcome? get variantOutcome => null;

  /// Set up a playable [Chess] position.
  ///
  /// Throws a [PositionError] if the [Setup] does not meet basic validity
  /// requirements.
  /// Optionnaly pass a `ignoreImpossibleCheck` boolean if you want to skip that
  /// requirement.
  factory Chess.fromSetup(Setup setup, {bool? ignoreImpossibleCheck}) {
    final pos = Chess._fromSetupUnchecked(setup);
    pos.validate(ignoreImpossibleCheck: ignoreImpossibleCheck);
    return pos;
  }

  @override
  Chess _copyWith({
    Board? board,
    Pockets? pockets,
    Side? turn,
    Castles? castles,
    Square? epSquare,
    int? halfmoves,
    int? fullmoves,
  }) {
    return Chess(
      board: board ?? this.board,
      pockets: pockets,
      turn: turn ?? this.turn,
      castles: castles ?? this.castles,
      epSquare: epSquare,
      halfmoves: halfmoves ?? this.halfmoves,
      fullmoves: fullmoves ?? this.fullmoves,
    );
  }
}

/// A variant of chess where you lose all your pieces or get stalemated to win.
@immutable
class Antichess extends Position<Antichess> {
  const Antichess({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
  });

  Antichess._fromSetupUnchecked(super.setup) : super._fromSetupUnchecked();

  const Antichess._initial() : super._initial();

  static const initial = Antichess._initial();

  @override
  Variant get variant => Variant.antichess;

  @override
  bool get isVariantEnd => board.bySide(turn).isEmpty;

  @override
  Outcome? get variantOutcome {
    if (isVariantEnd || isStalemate) {
      return Outcome(winner: turn);
    }
    return null;
  }

  /// Set up a playable [Antichess] position.
  ///
  /// Throws a [PositionError] if the [Setup] does not meet basic validity
  /// requirements.
  /// Optionnaly pass a `ignoreImpossibleCheck` boolean if you want to skip that
  /// requirement.
  factory Antichess.fromSetup(Setup setup, {bool? ignoreImpossibleCheck}) {
    final pos = Antichess._fromSetupUnchecked(setup);
    final noCastles = pos._copyWith(castles: Castles.empty);
    noCastles.validate(ignoreImpossibleCheck: ignoreImpossibleCheck);
    return noCastles;
  }

  @override
  void validate({bool? ignoreImpossibleCheck}) {
    if (board.occupied.isEmpty) {
      throw PositionError.empty;
    }
    if (SquareSet.backranks.isIntersected(board.pawns)) {
      throw PositionError.pawnsOnBackrank;
    }
  }

  @override
  SquareSet kingAttackers(Square square, Side attacker, {SquareSet? occupied}) {
    return SquareSet.empty;
  }

  @override
  _Context _makeContext() {
    final ctx = super._makeContext();
    if (epSquare != null &&
        pawnAttacks(opposite(turn), epSquare!)
            .isIntersected(board.piecesOf(turn, Role.pawn))) {
      return ctx.copyWith(mustCapture: true);
    }
    final enemy = board.bySide(opposite(turn));
    for (final from in board.bySide(turn).squares) {
      if (_pseudoLegalMoves(this, from, ctx).isIntersected(enemy)) {
        return ctx.copyWith(mustCapture: true);
      }
    }
    return ctx;
  }

  @override
  SquareSet _legalMovesOf(Square square, {_Context? context}) {
    final ctx = context ?? _makeContext();
    final dests = _pseudoLegalMoves(this, square, ctx);
    final enemy = board.bySide(opposite(turn));
    return dests &
        (ctx.mustCapture
            ? epSquare != null && board.roleAt(square) == Role.pawn
                ? enemy.withSquare(epSquare!)
                : enemy
            : SquareSet.full);
  }

  @override
  bool hasInsufficientMaterial(Side side) {
    if (board.bySide(side).isEmpty) return false;
    if (board.bySide(opposite(side)).isEmpty) return true;
    if (board.occupied == board.bishops) {
      final weSomeOnLight =
          board.bySide(side).isIntersected(SquareSet.lightSquares);
      final weSomeOnDark =
          board.bySide(side).isIntersected(SquareSet.darkSquares);
      final theyAllOnDark =
          board.bySide(opposite(side)).isDisjoint(SquareSet.lightSquares);
      final theyAllOnLight =
          board.bySide(opposite(side)).isDisjoint(SquareSet.darkSquares);
      return (weSomeOnLight && theyAllOnDark) ||
          (weSomeOnDark && theyAllOnLight);
    }
    if (board.occupied == board.knights && board.occupied.size == 2) {
      return (board.white.isIntersected(SquareSet.lightSquares) !=
              board.black.isIntersected(SquareSet.darkSquares)) !=
          (turn == side);
    }
    return false;
  }

  @override
  Antichess _copyWith({
    Board? board,
    Pockets? pockets,
    Side? turn,
    Castles? castles,
    Square? epSquare,
    int? halfmoves,
    int? fullmoves,
  }) {
    return Antichess(
      board: board ?? this.board,
      pockets: pockets,
      turn: turn ?? this.turn,
      castles: castles ?? this.castles,
      epSquare: epSquare,
      halfmoves: halfmoves ?? this.halfmoves,
      fullmoves: fullmoves ?? this.fullmoves,
    );
  }
}

/// A variant of chess where captures cause an explosion to the surrounding pieces.
@immutable
class Atomic extends Position<Atomic> {
  const Atomic({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
  });

  Atomic._fromSetupUnchecked(super.setup) : super._fromSetupUnchecked();
  const Atomic._initial() : super._initial();

  static const initial = Atomic._initial();

  @override
  Variant get variant => Variant.atomic;

  @override
  bool get isVariantEnd => variantOutcome != null;

  @override
  Outcome? get variantOutcome {
    for (final color in Side.values) {
      if (board.piecesOf(color, Role.king).isEmpty) {
        return Outcome(winner: opposite(color));
      }
    }
    return null;
  }

  /// Set up a playable [Atomic] position.
  ///
  /// Throws a [PositionError] if the [Setup] does not meet basic validity
  /// requirements.
  /// Optionnaly pass a `ignoreImpossibleCheck` boolean if you want to skip that
  /// requirement.
  factory Atomic.fromSetup(Setup setup, {bool? ignoreImpossibleCheck}) {
    final pos = Atomic._fromSetupUnchecked(setup);
    pos.validate(ignoreImpossibleCheck: ignoreImpossibleCheck);
    return pos;
  }

  /// Attacks that a king on `square` would have to deal with.
  ///
  /// Contrary to chess, in Atomic kings can attack each other, without causing
  /// check.
  @override
  SquareSet kingAttackers(Square square, Side attacker, {SquareSet? occupied}) {
    final attackerKings = board.piecesOf(attacker, Role.king);
    if (attackerKings.isEmpty ||
        kingAttacks(square).isIntersected(attackerKings)) {
      return SquareSet.empty;
    }
    return super.kingAttackers(square, attacker, occupied: occupied);
  }

  /// Checks the legality of this position.
  ///
  /// Validation is like chess, but it allows our king to be missing.
  /// Throws a [PositionError] if it does not meet basic validity requirements.
  @override
  void validate({bool? ignoreImpossibleCheck}) {
    if (board.occupied.isEmpty) {
      throw PositionError.empty;
    }
    if (board.kings.size > 2) {
      throw PositionError.kings;
    }
    final otherKing = board.kingOf(opposite(turn));
    if (otherKing == null) {
      throw PositionError.kings;
    }
    if (kingAttackers(otherKing, turn).isNotEmpty) {
      throw PositionError.oppositeCheck;
    }
    if (SquareSet.backranks.isIntersected(board.pawns)) {
      throw PositionError.pawnsOnBackrank;
    }
    final skipImpossibleCheck = ignoreImpossibleCheck ?? false;
    final ourKing = board.kingOf(turn);
    if (!skipImpossibleCheck && ourKing != null) {
      _validateCheckers(ourKing);
    }
  }

  @override
  void _validateCheckers(Square ourKing) {
    // Other king moving away can cause many checks to be given at the
    // same time. Not checking details or even that the king is close enough.
    if (epSquare == null) {
      super._validateCheckers(ourKing);
    }
  }

  /// Plays a move without checking if the move is legal.
  ///
  /// In addition to standard rules, all captures cause an explosion by which
  /// the captured piece, the piece used to capture, and all surrounding pieces
  /// except pawns that are within a one square radius are removed from the
  /// board.
  @override
  Atomic playUnchecked(Move move) {
    final castlingSide = _getCastlingSide(move);
    final capturedPiece = castlingSide == null ? board.pieceAt(move.to) : null;
    final isCapture = capturedPiece != null || move.to == epSquare;
    final newPos = super.playUnchecked(move) as Atomic;

    if (isCapture) {
      Castles newCastles = newPos.castles;
      Board newBoard = newPos.board.removePieceAt(move.to);
      for (final explode in kingAttacks(move.to)
          .intersect(newBoard.occupied)
          .diff(newBoard.pawns)
          .squares) {
        final piece = newBoard.pieceAt(explode);
        newBoard = newBoard.removePieceAt(explode);
        if (piece != null) {
          if (piece.role == Role.rook) {
            newCastles = newCastles.discardRookAt(explode);
          }
          if (piece.role == Role.king) {
            newCastles = newCastles.discardSide(piece.color);
          }
        }
      }
      return newPos._copyWith(board: newBoard, castles: newCastles);
    } else {
      return newPos;
    }
  }

  /// Tests if a [Side] has insufficient winning material.
  @override
  bool hasInsufficientMaterial(Side side) {
    // Remaining material does not matter if the enemy king is already
    // exploded.
    if (board.piecesOf(opposite(side), Role.king).isEmpty) return false;

    // Bare king cannot mate.
    if (board.bySide(side).diff(board.kings).isEmpty) return true;

    // As long as the enemy king is not alone, there is always a chance their
    // own pieces explode next to it.
    if (board.bySide(opposite(side)).diff(board.kings).isNotEmpty) {
      // Unless there are only bishops that cannot explode each other.
      if (board.occupied == board.bishops | board.kings) {
        if (!(board.bishops & board.white)
            .isIntersected(SquareSet.darkSquares)) {
          return !(board.bishops & board.black)
              .isIntersected(SquareSet.lightSquares);
        }
        if (!(board.bishops & board.white)
            .isIntersected(SquareSet.lightSquares)) {
          return !(board.bishops & board.black)
              .isIntersected(SquareSet.darkSquares);
        }
      }
      return false;
    }

    // Queen or pawn (future queen) can give mate against bare king.
    if (board.queens.isNotEmpty || board.pawns.isNotEmpty) return false;

    // Single knight, bishop or rook cannot mate against bare king.
    if ((board.knights | board.bishops | board.rooks).size == 1) {
      return true;
    }

    // If only knights, more than two are required to mate bare king.
    if (board.occupied == board.knights | board.kings) {
      return board.knights.size <= 2;
    }

    return false;
  }

  @override
  SquareSet _legalMovesOf(Square square, {_Context? context}) {
    SquareSet moves = SquareSet.empty;
    final ctx = context ?? _makeContext();
    for (final to in _pseudoLegalMoves(this, square, ctx).squares) {
      final after = playUnchecked(NormalMove(from: square, to: to));
      final ourKing = after.board.kingOf(turn);
      if (ourKing != null &&
          (after.board.kingOf(after.turn) == null ||
              after.kingAttackers(ourKing, after.turn).isEmpty)) {
        moves = moves.withSquare(to);
      }
    }
    return moves;
  }

  @override
  Atomic _copyWith({
    Board? board,
    Pockets? pockets,
    Side? turn,
    Castles? castles,
    Square? epSquare,
    int? halfmoves,
    int? fullmoves,
  }) {
    return Atomic(
      board: board ?? this.board,
      pockets: pockets,
      turn: turn ?? this.turn,
      castles: castles ?? this.castles,
      epSquare: epSquare,
      halfmoves: halfmoves ?? this.halfmoves,
      fullmoves: fullmoves ?? this.fullmoves,
    );
  }
}

/// A variant where captured pieces can be dropped back on the board instead of moving a piece.
@immutable
class Crazyhouse extends Position<Crazyhouse> {
  const Crazyhouse({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
  });

  Crazyhouse._fromSetupUnchecked(super.setup) : super._fromSetupUnchecked();

  static const initial = Crazyhouse(
    board: Board.standard,
    pockets: Pockets.empty,
    turn: Side.white,
    castles: Castles.standard,
    halfmoves: 0,
    fullmoves: 1,
  );

  @override
  Variant get variant => Variant.crazyhouse;

  @override
  bool get isVariantEnd => false;

  @override
  Outcome? get variantOutcome => null;

  /// Set up a playable [Crazyhouse] position.
  ///
  /// Throws a [PositionError] if the [Setup] does not meet basic validity
  /// requirements.
  /// Optionnaly pass a `ignoreImpossibleCheck` boolean if you want to skip that
  /// requirement.
  factory Crazyhouse.fromSetup(Setup setup, {bool? ignoreImpossibleCheck}) {
    final pos = Crazyhouse._fromSetupUnchecked(setup)._copyWith(
      pockets: setup.pockets ?? Pockets.empty,
      board: setup.board.withPromoted(setup.board.promoted
          .intersect(setup.board.occupied)
          .diff(setup.board.kings)
          .diff(setup.board.pawns)),
    );
    pos.validate(ignoreImpossibleCheck: ignoreImpossibleCheck);
    return pos;
  }

  @override
  void validate({bool? ignoreImpossibleCheck}) {
    super.validate(ignoreImpossibleCheck: ignoreImpossibleCheck);
    if (pockets == null) {
      throw PositionError.variant;
    } else {
      if (pockets!.count(Role.king) > 0) {
        throw PositionError.kings;
      }
      if (pockets!.size + board.occupied.size > 64) {
        throw PositionError.variant;
      }
    }
  }

  @override
  bool hasInsufficientMaterial(Side side) {
    if (pockets == null) {
      return super.hasInsufficientMaterial(side);
    }
    return board.occupied.size + pockets!.size <= 3 &&
        board.pawns.isEmpty &&
        board.promoted.isEmpty &&
        board.rooksAndQueens.isEmpty &&
        pockets!.count(Role.pawn) <= 0 &&
        pockets!.count(Role.rook) <= 0 &&
        pockets!.count(Role.queen) <= 0;
  }

  @override
  SquareSet get legalDrops {
    final mask = board.occupied
        .complement()
        .intersect(pockets != null && pockets!.hasQuality(turn)
            ? SquareSet.full
            : pockets != null && pockets!.hasPawn(turn)
                ? SquareSet.backranks.complement()
                : SquareSet.empty);

    final ctx = _makeContext();
    if (ctx.king != null && ctx.checkers.isNotEmpty) {
      final checker = ctx.checkers.singleSquare;
      if (checker == null) {
        return SquareSet.empty;
      } else {
        return mask & between(checker, ctx.king!);
      }
    } else {
      return mask;
    }
  }

  @override
  Crazyhouse _copyWith({
    Board? board,
    Pockets? pockets,
    Side? turn,
    Castles? castles,
    Square? epSquare,
    int? halfmoves,
    int? fullmoves,
  }) {
    return Crazyhouse(
      board: board ?? this.board,
      pockets: pockets,
      turn: turn ?? this.turn,
      castles: castles ?? this.castles,
      epSquare: epSquare,
      halfmoves: halfmoves ?? this.halfmoves,
      fullmoves: fullmoves ?? this.fullmoves,
    );
  }
}

/// A variant similar to standard chess, where you win by putting your king on the center
/// of the board.
@immutable
class KingOfTheHill extends Position<KingOfTheHill> {
  const KingOfTheHill({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
  });

  KingOfTheHill._fromSetupUnchecked(super.setup) : super._fromSetupUnchecked();
  const KingOfTheHill._initial() : super._initial();

  static const initial = KingOfTheHill._initial();

  @override
  Variant get variant => Variant.kingofthehill;

  @override
  bool get isVariantEnd => board.kings.isIntersected(SquareSet.center);

  @override
  Outcome? get variantOutcome {
    for (final color in Side.values) {
      if (board.piecesOf(color, Role.king).isIntersected(SquareSet.center)) {
        return Outcome(winner: color);
      }
    }
    return null;
  }

  /// Set up a playable [KingOfTheHill] position.
  ///
  /// Throws a [PositionError] if the [Setup] does not meet basic validity
  /// requirements.
  /// Optionnaly pass a `ignoreImpossibleCheck` boolean if you want to skip that
  /// requirement.
  factory KingOfTheHill.fromSetup(Setup setup, {bool? ignoreImpossibleCheck}) {
    final pos = KingOfTheHill._fromSetupUnchecked(setup);
    pos.validate(ignoreImpossibleCheck: ignoreImpossibleCheck);
    return pos;
  }

  @override
  bool hasInsufficientMaterial(Side side) => false;

  @override
  KingOfTheHill _copyWith({
    Board? board,
    Pockets? pockets,
    Side? turn,
    Castles? castles,
    Square? epSquare,
    int? halfmoves,
    int? fullmoves,
  }) {
    return KingOfTheHill(
      board: board ?? this.board,
      pockets: pockets,
      turn: turn ?? this.turn,
      castles: castles ?? this.castles,
      epSquare: epSquare,
      halfmoves: halfmoves ?? this.halfmoves,
      fullmoves: fullmoves ?? this.fullmoves,
    );
  }
}

/// A variant similar to standard chess, where you can win if you put your opponent king
/// into the third check.
@immutable
class ThreeCheck extends Position<ThreeCheck> {
  const ThreeCheck({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
    required this.remainingChecks,
  });

  /// Number of remainingChecks for white (`item1`) and black (`item2`).
  final Tuple2<int, int> remainingChecks;

  const ThreeCheck._initial()
      : remainingChecks = _defaultRemainingChecks,
        super._initial();

  static const initial = ThreeCheck._initial();

  static const _defaultRemainingChecks = Tuple2(3, 3);

  @override
  Variant get variant => Variant.threecheck;

  @override
  bool get isVariantEnd =>
      remainingChecks.item1 <= 0 || remainingChecks.item2 <= 0;

  @override
  Outcome? get variantOutcome {
    if (remainingChecks.item1 <= 0) {
      return Outcome.whiteWins;
    }
    if (remainingChecks.item2 <= 0) {
      return Outcome.blackWins;
    }
    return null;
  }

  /// Set up a playable [ThreeCheck] position.
  ///
  /// Throws a [PositionError] if the [Setup] does not meet basic validity
  /// requirements.
  /// Optionnaly pass a `ignoreImpossibleCheck` boolean if you want to skip that
  /// requirement.
  factory ThreeCheck.fromSetup(Setup setup, {bool? ignoreImpossibleCheck}) {
    if (setup.remainingChecks == null) {
      throw PositionError.variant;
    } else {
      final pos = ThreeCheck(
        board: setup.board,
        turn: setup.turn,
        castles: Castles.fromSetup(setup),
        epSquare: _validEpSquare(setup),
        halfmoves: setup.halfmoves,
        fullmoves: setup.fullmoves,
        remainingChecks: setup.remainingChecks!,
      );
      pos.validate(ignoreImpossibleCheck: ignoreImpossibleCheck);
      return pos;
    }
  }

  @override
  String get fen {
    return Setup(
      board: board,
      turn: turn,
      unmovedRooks: castles.unmovedRooks,
      epSquare: _legalEpSquare(),
      halfmoves: halfmoves,
      fullmoves: fullmoves,
      remainingChecks: remainingChecks,
    ).fen;
  }

  @override
  bool hasInsufficientMaterial(Side side) =>
      board.piecesOf(side, Role.king) == board.bySide(side);

  @override
  ThreeCheck playUnchecked(Move move) {
    final newPos = super.playUnchecked(move) as ThreeCheck;
    if (newPos.isCheck) {
      return newPos._copyWith(
          remainingChecks: turn == Side.white
              ? remainingChecks
                  .withItem1(math.max(remainingChecks.item1 - 1, 0))
              : remainingChecks
                  .withItem2(math.max(remainingChecks.item2 - 1, 0)));
    } else {
      return newPos;
    }
  }

  @override
  ThreeCheck _copyWith({
    Board? board,
    Pockets? pockets,
    Side? turn,
    Castles? castles,
    Square? epSquare,
    int? halfmoves,
    int? fullmoves,
    Tuple2<int, int>? remainingChecks,
  }) {
    return ThreeCheck(
      board: board ?? this.board,
      pockets: pockets,
      turn: turn ?? this.turn,
      castles: castles ?? this.castles,
      epSquare: epSquare,
      halfmoves: halfmoves ?? this.halfmoves,
      fullmoves: fullmoves ?? this.fullmoves,
      remainingChecks: remainingChecks ?? this.remainingChecks,
    );
  }
}

/// The outcome of a [Position]. No `winner` means a draw.
@immutable
class Outcome {
  const Outcome({this.winner});

  final Side? winner;

  static const whiteWins = Outcome(winner: Side.white);
  static const blackWins = Outcome(winner: Side.black);
  static const draw = Outcome();

  @override
  String toString() {
    return 'winner: $winner';
  }

  @override
  bool operator ==(Object other) => other is Outcome && winner == other.winner;

  @override
  int get hashCode => winner.hashCode;
}

enum IllegalSetup {
  /// There are no pieces on the board.
  empty,

  /// The player not to move is in check.
  oppositeCheck,

  /// There are impossibly many checkers, two sliding checkers are
  /// aligned, or check is not possible because the last move was a
  /// double pawn push.
  ///
  /// Such a position cannot be reached by any sequence of legal moves.
  impossibleCheck,

  /// There are pawns on the backrank.
  pawnsOnBackrank,

  /// A king is missing, or there are too many kings.
  kings,

  /// A variant specific rule is violated.
  variant,
}

@immutable
class PlayError implements Exception {
  final String message;
  const PlayError(this.message);

  @override
  String toString() => 'PlayError($message)';
}

/// Error when trying to create a [Position] from an illegal [Setup].
@immutable
class PositionError implements Exception {
  final IllegalSetup cause;
  const PositionError(this.cause);

  static const empty = PositionError(IllegalSetup.empty);
  static const oppositeCheck = PositionError(IllegalSetup.oppositeCheck);
  static const impossibleCheck = PositionError(IllegalSetup.impossibleCheck);
  static const pawnsOnBackrank = PositionError(IllegalSetup.pawnsOnBackrank);
  static const kings = PositionError(IllegalSetup.kings);
  static const variant = PositionError(IllegalSetup.variant);

  @override
  String toString() => 'PositionError(${cause.name})';
}

enum CastlingSide {
  queen,
  king;
}

@immutable
class Castles {
  final SquareSet unmovedRooks;

  /// Rooks positions pair.
  ///
  /// First item is queen side, second is king side.
  final BySide<Tuple2<Square?, Square?>> rook;

  /// Squares between the white king and rooks.
  ///
  /// First item is queen side, second is king side.
  final BySide<Tuple2<SquareSet, SquareSet>> path;

  const Castles({
    required this.unmovedRooks,
    required this.rook,
    required this.path,
  });

  static const standard = Castles(
    unmovedRooks: SquareSet.corners,
    rook: {Side.white: Tuple2(0, 7), Side.black: Tuple2(56, 63)},
    path: {
      Side.white:
          Tuple2(SquareSet(0x000000000000000e), SquareSet(0x0000000000000060)),
      Side.black:
          Tuple2(SquareSet(0x0e00000000000000), SquareSet(0x6000000000000000))
    },
  );

  static const empty = Castles(
    unmovedRooks: SquareSet.empty,
    rook: {Side.white: Tuple2(null, null), Side.black: Tuple2(null, null)},
    path: {
      Side.white: Tuple2(SquareSet.empty, SquareSet.empty),
      Side.black: Tuple2(SquareSet.empty, SquareSet.empty)
    },
  );

  factory Castles.fromSetup(Setup setup) {
    Castles castles = Castles.empty;
    final rooks = setup.unmovedRooks & setup.board.rooks;
    for (final side in Side.values) {
      final backrank = SquareSet.backrankOf(side);
      final king = setup.board.kingOf(side);
      if (king == null || !backrank.has(king)) continue;
      final backrankRooks = rooks & setup.board.bySide(side) & backrank;
      if (backrankRooks.first != null && backrankRooks.first! < king) {
        castles =
            castles._add(side, CastlingSide.queen, king, backrankRooks.first!);
      }
      if (backrankRooks.last != null && king < backrankRooks.last!) {
        castles =
            castles._add(side, CastlingSide.king, king, backrankRooks.last!);
      }
    }
    return castles;
  }

  /// Gets the rook [Square] by side and castling side.
  Square? rookOf(Side side, CastlingSide cs) =>
      cs == CastlingSide.queen ? rook[side]!.item1 : rook[side]!.item2;

  /// Gets the squares that need to be empty so that castling is possible
  /// on the given side.
  ///
  /// We're assuming the player still has the required castling rigths.
  SquareSet pathOf(Side side, CastlingSide cs) =>
      cs == CastlingSide.queen ? path[side]!.item1 : path[side]!.item2;

  Castles discardRookAt(Square square) {
    final whiteRook = rook[Side.white]!;
    final blackRook = rook[Side.black]!;
    return unmovedRooks.has(square)
        ? _copyWith(
            unmovedRooks: unmovedRooks.withoutSquare(square),
            rook: {
              if (square <= 7)
                Side.white: whiteRook.item1 == square
                    ? whiteRook.withItem1(null)
                    : whiteRook.item2 == square
                        ? whiteRook.withItem2(null)
                        : whiteRook,
              if (square >= 56)
                Side.black: blackRook.item1 == square
                    ? blackRook.withItem1(null)
                    : blackRook.item2 == square
                        ? blackRook.withItem2(null)
                        : blackRook,
            },
          )
        : this;
  }

  Castles discardSide(Side side) {
    return _copyWith(
      unmovedRooks: unmovedRooks.diff(SquareSet.backrankOf(side)),
      rook: {
        side: const Tuple2(null, null),
      },
    );
  }

  Castles _add(Side side, CastlingSide cs, Square king, Square rook) {
    final kingTo = _kingCastlesTo(side, cs);
    final rookTo = _rookCastlesTo(side, cs);
    final path = between(rook, rookTo)
        .withSquare(rookTo)
        .union(between(king, kingTo).withSquare(kingTo))
        .withoutSquare(king)
        .withoutSquare(rook);
    return _copyWith(
      unmovedRooks: unmovedRooks.withSquare(rook),
      rook: {
        side: cs == CastlingSide.queen
            ? this.rook[side]!.withItem1(rook)
            : this.rook[side]!.withItem2(rook),
      },
      path: {
        side: cs == CastlingSide.queen
            ? this.path[side]!.withItem1(path)
            : this.path[side]!.withItem2(path),
      },
    );
  }

  Castles _copyWith({
    SquareSet? unmovedRooks,
    BySide<Tuple2<Square?, Square?>>? rook,
    BySide<Tuple2<SquareSet, SquareSet>>? path,
  }) {
    return Castles(
      unmovedRooks: unmovedRooks ?? this.unmovedRooks,
      rook:
          rook != null ? Map.unmodifiable({...this.rook, ...rook}) : this.rook,
      path:
          path != null ? Map.unmodifiable({...this.path, ...path}) : this.path,
    );
  }

  @override
  String toString() =>
      'Castles(unmovedRooks: $unmovedRooks, rook: $rook, path: $path)';

  @override
  bool operator ==(Object other) =>
      other is Castles &&
      other.unmovedRooks == unmovedRooks &&
      other.rook[Side.white] == rook[Side.white] &&
      other.rook[Side.black] == rook[Side.black] &&
      other.path[Side.white] == path[Side.white] &&
      other.path[Side.black] == path[Side.black];

  @override
  int get hashCode => Object.hash(unmovedRooks, rook[Side.white],
      rook[Side.black], path[Side.white], path[Side.black]);
}

@immutable
class _Context {
  const _Context({
    required this.isVariantEnd,
    required this.king,
    required this.blockers,
    required this.checkers,
    required this.mustCapture,
  });

  final bool isVariantEnd;
  final bool mustCapture;
  final Square? king;
  final SquareSet blockers;
  final SquareSet checkers;

  _Context copyWith({
    bool? isVariantEnd,
    bool? mustCapture,
    Square? king,
    SquareSet? blockers,
    SquareSet? checkers,
  }) {
    return _Context(
      isVariantEnd: isVariantEnd ?? this.isVariantEnd,
      mustCapture: mustCapture ?? this.mustCapture,
      king: king,
      blockers: blockers ?? this.blockers,
      checkers: checkers ?? this.checkers,
    );
  }
}

Square _rookCastlesTo(Side side, CastlingSide cs) {
  return side == Side.white
      ? (cs == CastlingSide.queen ? 3 : 5)
      : cs == CastlingSide.queen
          ? 59
          : 61;
}

Square _kingCastlesTo(Side side, CastlingSide cs) {
  return side == Side.white
      ? (cs == CastlingSide.queen ? 2 : 6)
      : cs == CastlingSide.queen
          ? 58
          : 62;
}

Square? _validEpSquare(Setup setup) {
  if (setup.epSquare == null) return null;
  final epRank = setup.turn == Side.white ? 5 : 2;
  final forward = setup.turn == Side.white ? 8 : -8;
  if (squareRank(setup.epSquare!) != epRank) return null;
  if (setup.board.occupied.has(setup.epSquare! + forward)) return null;
  final pawn = setup.epSquare! - forward;
  if (!setup.board.pawns.has(pawn) ||
      !setup.board.bySide(opposite(setup.turn)).has(pawn)) {
    return null;
  }
  return setup.epSquare;
}

SquareSet _pseudoLegalMoves(Position pos, Square square, _Context context) {
  if (pos.isVariantEnd) return SquareSet.empty;
  final piece = pos.board.pieceAt(square);
  if (piece == null || piece.color != pos.turn) return SquareSet.empty;

  SquareSet pseudo = attacks(piece, square, pos.board.occupied);
  if (piece.role == Role.pawn) {
    SquareSet captureTargets = pos.board.bySide(opposite(pos.turn));
    if (pos.epSquare != null) {
      captureTargets = captureTargets.withSquare(pos.epSquare!);
    }
    pseudo = pseudo & captureTargets;
    final delta = pos.turn == Side.white ? 8 : -8;
    final step = square + delta;
    if (0 <= step && step < 64 && !pos.board.occupied.has(step)) {
      pseudo = pseudo.withSquare(step);
      final canDoubleStep =
          pos.turn == Side.white ? square < 16 : square >= 64 - 16;
      final doubleStep = step + delta;
      if (canDoubleStep && !pos.board.occupied.has(doubleStep)) {
        pseudo = pseudo.withSquare(doubleStep);
      }
    }
    return pseudo;
  } else {
    pseudo = pseudo.diff(pos.board.bySide(pos.turn));
  }
  if (square == context.king) {
    return pseudo
        .union(pos._castlingMove(CastlingSide.queen, context))
        .union(pos._castlingMove(CastlingSide.king, context));
  } else {
    return pseudo;
  }
}
