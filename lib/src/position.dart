import 'package:meta/meta.dart';
import 'dart:math' as math;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'attacks.dart';
import 'castles.dart';
import 'debug.dart';
import 'models.dart';
import 'board.dart';
import 'setup.dart';
import 'square_set.dart';
import 'utils.dart';

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

  /// The [Rule] of this position.
  Rule get rule;

  /// Creates a copy of this position with some fields changed.
  Position<T> copyWith({
    Board? board,
    Pockets? pockets,
    Side? turn,
    Castles? castles,
    Square? epSquare,
    int? halfmoves,
    int? fullmoves,
  });

  /// Create a [Position] from a [Setup] and [Rule].
  static Position setupPosition(Rule rule, Setup setup,
      {bool? ignoreImpossibleCheck}) {
    switch (rule) {
      case Rule.chess:
        return Chess.fromSetup(setup,
            ignoreImpossibleCheck: ignoreImpossibleCheck);
      case Rule.antichess:
        return Antichess.fromSetup(setup,
            ignoreImpossibleCheck: ignoreImpossibleCheck);
      case Rule.atomic:
        return Atomic.fromSetup(setup,
            ignoreImpossibleCheck: ignoreImpossibleCheck);
      case Rule.kingofthehill:
        return KingOfTheHill.fromSetup(setup,
            ignoreImpossibleCheck: ignoreImpossibleCheck);
      case Rule.crazyhouse:
        return Crazyhouse.fromSetup(setup,
            ignoreImpossibleCheck: ignoreImpossibleCheck);
      case Rule.threecheck:
        return ThreeCheck.fromSetup(setup,
            ignoreImpossibleCheck: ignoreImpossibleCheck);
      case Rule.horde:
        return Horde.fromSetup(setup,
            ignoreImpossibleCheck: ignoreImpossibleCheck);
      case Rule.racingKings:
        return RacingKings.fromSetup(setup,
            ignoreImpossibleCheck: ignoreImpossibleCheck);
    }
  }

  /// Returns the initial [Position] for the corresponding [Rule].
  static Position initialPosition(Rule rule) {
    switch (rule) {
      case Rule.chess:
        return Chess.initial;
      case Rule.antichess:
        return Antichess.initial;
      case Rule.atomic:
        return Atomic.initial;
      case Rule.kingofthehill:
        return KingOfTheHill.initial;
      case Rule.threecheck:
        return ThreeCheck.initial;
      case Rule.crazyhouse:
        return Crazyhouse.initial;
      case Rule.horde:
        return Horde.initial;
      case Rule.racingKings:
        return RacingKings.initial;
    }
  }

  /// Checks if the game is over due to a special variant end condition.
  bool get isVariantEnd;

  /// Tests special variant winning, losing and drawing conditions.
  Outcome? get variantOutcome;

  /// Gets the current ply.
  int get ply => fullmoves * 2 - (turn == Side.white ? 2 : 1);

  /// Gets the FEN string of this position.
  ///
  /// Contrary to the FEN given by [Setup], this should always be a legal
  /// position.
  String get fen {
    return Setup(
      board: board,
      pockets: pockets,
      turn: turn,
      castlingRights: castles.castlingRights,
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
      return Outcome(winner: turn.opposite);
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
  ///
  /// Returns a [SquareSet] of all the legal moves for each [Square].
  ///
  /// In order to support Chess960, the castling move format is encoded as the
  /// king-to-rook move only.
  ///
  /// Use the [makeLegalMoves] helper to get all the legal moves including alternative
  /// castling moves.
  IMap<Square, SquareSet> get legalMoves {
    final context = _makeContext();
    if (context.isVariantEnd) return IMap(const {});
    return IMap({
      for (final s in board.bySide(turn).squares)
        s: _legalMovesOf(s, context: context)
    });
  }

  /// Gets all the legal drops of this position.
  SquareSet get legalDrops => SquareSet.empty;

  /// Square set of pieces giving check.
  SquareSet get checkers {
    final king = board.kingOf(turn);
    return king != null ? kingAttackers(king, turn.opposite) : SquareSet.empty;
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
              .bySide(side.opposite)
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
    switch (move) {
      case NormalMove(from: final f, to: final t, promotion: final p):
        if (p == Role.pawn) return false;
        if (p == Role.king && this is! Antichess) return false;
        if (p != null && (!board.pawns.has(f) || !SquareSet.backranks.has(t))) {
          return false;
        }
        final legalMoves = _legalMovesOf(f);
        return legalMoves.has(t) || legalMoves.has(normalizeMove(move).to);
      case DropMove(to: final t, role: final r):
        if (pockets == null || pockets!.of(turn, r) <= 0) {
          return false;
        }
        if (r == Role.pawn && SquareSet.backranks.has(t)) {
          return false;
        }
        return legalDrops.has(t);
    }
  }

  /// Gets the legal moves for that [Square].
  SquareSet legalMovesOf(Square square) {
    return _legalMovesOf(square);
  }

  /// Parses a move in Standard Algebraic Notation.
  ///
  /// Returns a legal [Move] of the [Position] or `null`.
  Move? parseSan(String sanString) {
    final aIndex = 'a'.codeUnits[0];
    final hIndex = 'h'.codeUnits[0];
    final oneIndex = '1'.codeUnits[0];
    final eightIndex = '8'.codeUnits[0];
    String san = sanString;

    final firstAnnotationIndex = san.indexOf(RegExp('[!?#+]'));
    if (firstAnnotationIndex != -1) {
      san = san.substring(0, firstAnnotationIndex);
    }

    // Crazyhouse
    if (san.contains('@')) {
      if (san.length == 3 && san[0] != '@') {
        return null;
      }
      if (san.length == 4 && san[1] != '@') {
        return null;
      }
      final Role role;
      if (san.length == 3) {
        role = Role.pawn;
      } else if (san.length == 4) {
        final parsedRole = Role.fromChar(san[0]);
        if (parsedRole == null) {
          return null;
        }
        role = parsedRole;
      } else {
        return null;
      }
      final destination = Square.parse(san.substring(san.length - 2));
      if (destination == null) {
        return null;
      }
      final move = DropMove(to: destination, role: role);
      if (!isLegal(move)) {
        return null;
      }
      return move;
    }

    if (san == 'O-O') {
      final king = board.kingOf(turn);
      final rook = castles.rookOf(turn, CastlingSide.king);
      if (king == null || rook == null) {
        return null;
      }
      final move = NormalMove(from: king, to: rook);
      if (!isLegal(move)) {
        return null;
      }
      return move;
    }
    if (san == 'O-O-O') {
      final king = board.kingOf(turn);
      final rook = castles.rookOf(turn, CastlingSide.queen);
      if (king == null || rook == null) {
        return null;
      }
      final move = NormalMove(from: king, to: rook);
      if (!isLegal(move)) {
        return null;
      }
      return move;
    }

    final isPromotion = san.contains('=');
    final isCapturing = san.contains('x');
    Rank? pawnRank;
    if (oneIndex <= san.codeUnits[0] && san.codeUnits[0] <= eightIndex) {
      pawnRank = Rank(san.codeUnits[0] - oneIndex);
      san = san.substring(1);
    }
    final isPawnMove = aIndex <= san.codeUnits[0] && san.codeUnits[0] <= hIndex;

    if (isPawnMove) {
      // Every pawn move has a destination (e.g. d4)
      // Optionally, pawn moves have a promotion
      // If the move is a capture then it will include the source file

      final colorFilter = board.bySide(turn);
      final pawnFilter = board.byRole(Role.pawn);
      SquareSet filter = colorFilter.intersect(pawnFilter);
      Role? promotionRole;

      // We can look at the first character of any pawn move
      // in order to determine which file the pawn will be moving
      // from
      final sourceFileCharacter = san.codeUnits[0];
      if (sourceFileCharacter < aIndex || sourceFileCharacter > hIndex) {
        return null;
      }

      final sourceFile = File(sourceFileCharacter - aIndex);
      final sourceFileFilter = SquareSet.fromFile(sourceFile);
      filter = filter.intersect(sourceFileFilter);

      if (isCapturing) {
        // Invalid SAN
        if (san[1] != 'x') {
          return null;
        }

        // Remove the source file character and the capture marker
        san = san.substring(2);
      }

      if (isPromotion) {
        // Invalid SAN
        if (san[san.length - 2] != '=') {
          return null;
        }

        final promotionCharacter = san[san.length - 1];
        promotionRole = Role.fromChar(promotionCharacter);

        // Remove the promotion string
        san = san.substring(0, san.length - 2);
      }

      // After handling captures and promotions, the
      // remaining destination square should contain
      // two characters.
      if (san.length != 2) {
        return null;
      }

      final destination = Square.parse(san);
      if (destination == null) {
        return null;
      }

      // There may be many pawns in the corresponding file
      // The corect choice will always be the pawn behind the destination square that is furthest down the board
      for (final rank in Rank.values) {
        final rankFilter = SquareSet.fromRank(rank).complement();
        // If the square is behind or on this rank, the rank it will not contain the source pawn
        if (turn == Side.white && rank >= destination.rank ||
            turn == Side.black && rank <= destination.rank) {
          filter = filter.intersect(rankFilter);
        }
      }

      // If the pawn rank has been overspecified, then verify the rank
      if (pawnRank != null) {
        filter = filter.intersect(SquareSet.fromRank(pawnRank));
      }

      final source = (turn == Side.white) ? filter.last : filter.first;

      // There are no valid candidates for the move
      if (source == null) {
        return null;
      }

      final move =
          NormalMove(from: source, to: destination, promotion: promotionRole);
      if (!isLegal(move)) {
        return null;
      }
      return move;
    }

    // The final two moves define the destination
    final destination = Square.parse(san.substring(san.length - 2));
    if (destination == null) {
      return null;
    }

    san = san.substring(0, san.length - 2);
    if (isCapturing) {
      // Invalid SAN
      if (san[san.length - 1] != 'x') {
        return null;
      }
      san = san.substring(0, san.length - 1);
    }

    // For non-pawn moves, the first character describes a role
    final role = Role.fromChar(san[0]);
    if (role == null) {
      return null;
    }
    if (role == Role.pawn) {
      return null;
    }
    san = san.substring(1);

    final colorFilter = board.bySide(turn);
    final roleFilter = board.byRole(role);
    SquareSet filter = colorFilter.intersect(roleFilter);

    // The remaining characters disambiguate the moves
    if (san.length > 2) {
      return null;
    }
    if (san.length == 2) {
      final sourceSquare = Square.parse(san);
      if (sourceSquare == null) {
        return null;
      }
      final squareFilter = SquareSet.fromSquare(sourceSquare);
      filter = filter.intersect(squareFilter);
    }
    if (san.length == 1) {
      final sourceCharacter = san.codeUnits[0];
      if (oneIndex <= sourceCharacter && sourceCharacter <= eightIndex) {
        final rank = Rank(sourceCharacter - oneIndex);
        final rankFilter = SquareSet.fromRank(rank);
        filter = filter.intersect(rankFilter);
      } else if (aIndex <= sourceCharacter && sourceCharacter <= hIndex) {
        final file = File(sourceCharacter - aIndex);
        final fileFilter = SquareSet.fromFile(file);
        filter = filter.intersect(fileFilter);
      } else {
        return null;
      }
    }

    Move? move;
    for (final square in filter.squares) {
      final candidateMove = NormalMove(from: square, to: destination);
      if (!isLegal(candidateMove)) {
        continue;
      }
      if (move == null) {
        move = candidateMove;
      } else {
        // Ambiguous notation
        return null;
      }
    }

    if (move == null) {
      return null;
    }

    return move;
  }

  /// Plays a move and returns the updated [Position].
  ///
  /// Throws a [PlayException] if the move is not legal.
  Position<T> play(Move move) {
    if (isLegal(move)) {
      return playUnchecked(move);
    } else {
      throw PlayException('Invalid move $move');
    }
  }

  /// Plays a move without checking if the move is legal and returns the updated [Position].
  Position<T> playUnchecked(Move move) {
    switch (move) {
      case NormalMove(from: final from, to: final to, promotion: final prom):
        final piece = board.pieceAt(from);
        if (piece == null) {
          return copyWith();
        }
        final castlingSide = _getCastlingSide(move);
        Square? epCaptureTarget;
        Square? newEpSquare;
        Board newBoard = board.removePieceAt(from);
        Castles newCastles = castles;
        if (piece.role == Role.pawn) {
          if (to == epSquare) {
            epCaptureTarget = Square(to + (turn == Side.white ? -8 : 8));
            newBoard = newBoard.removePieceAt(epCaptureTarget);
          }
          final delta = from - to;
          if (delta.abs() == 16 && from >= Square.a2 && from <= Square.h7) {
            newEpSquare = Square((from + to) >>> 1);
          }
        } else if (piece.role == Role.rook) {
          newCastles = newCastles.discardRookAt(from);
        } else if (piece.role == Role.king) {
          if (castlingSide != null) {
            final rookFrom = castles.rookOf(turn, castlingSide);
            if (rookFrom != null) {
              final rook = board.pieceAt(rookFrom);
              newBoard = newBoard
                  .removePieceAt(rookFrom)
                  .setPieceAt(kingCastlesTo(turn, castlingSide), piece);
              if (rook != null) {
                newBoard = newBoard.setPieceAt(
                    rookCastlesTo(turn, castlingSide), rook);
              }
            }
          }
          newCastles = newCastles.discardSide(turn);
        }

        if (castlingSide == null) {
          final newPiece = prom != null
              ? piece.copyWith(role: prom, promoted: pockets != null)
              : piece;
          newBoard = newBoard.setPieceAt(to, newPiece);
        }

        final capturedPiece = castlingSide == null
            ? board.pieceAt(to)
            : to == epSquare && epCaptureTarget != null
                ? board.pieceAt(epCaptureTarget)
                : null;
        final isCapture = capturedPiece != null;

        if (capturedPiece != null && capturedPiece.role == Role.rook) {
          newCastles = newCastles.discardRookAt(to);
        }

        return copyWith(
          halfmoves: isCapture || piece.role == Role.pawn ? 0 : halfmoves + 1,
          fullmoves: turn == Side.black ? fullmoves + 1 : fullmoves,
          pockets: capturedPiece != null
              ? pockets?.increment(capturedPiece.color.opposite,
                  capturedPiece.promoted ? Role.pawn : capturedPiece.role)
              : pockets,
          board: newBoard,
          turn: turn.opposite,
          castles: newCastles,
          epSquare: newEpSquare,
        );
      case DropMove(to: final to, role: final role):
        return copyWith(
          halfmoves: role == Role.pawn ? 0 : halfmoves + 1,
          fullmoves: turn == Side.black ? fullmoves + 1 : fullmoves,
          turn: turn.opposite,
          board: board.setPieceAt(to, Piece(color: turn, role: role)),
          pockets: pockets?.decrement(turn, role),
        );
    }
  }

  /// Returns the SAN of this [Move] and the updated [Position], without checking if the move is legal.
  (Position<T>, String) makeSanUnchecked(Move move) {
    final san = _makeSanWithoutSuffix(move);
    final newPos = playUnchecked(move);
    final suffixed = newPos.outcome?.winner != null
        ? '$san#'
        : newPos.isCheck
            ? '$san+'
            : san;
    return (newPos, suffixed);
  }

  /// Returns the SAN of this [Move] and the updated [Position].
  ///
  /// Throws a [PlayException] if the move is not legal.
  (Position<T>, String) makeSan(Move move) {
    if (isLegal(move)) {
      return makeSanUnchecked(move);
    } else {
      throw PlayException('Invalid move $move');
    }
  }

  /// Returns the SAN of this [Move] from the current [Position].
  ///
  /// Throws a [PlayException] if the move is not legal.
  @Deprecated('Use makeSan instead')
  String toSan(Move move) {
    if (isLegal(move)) {
      return makeSanUnchecked(move).$2;
    } else {
      throw PlayException('Invalid move $move');
    }
  }

  /// Normalize a [NormalMove] to avoid castling inconsistencies.
  ///
  /// The normalized form of a castling move is the king-to-rook move.
  ///
  /// This method does not check if the move is legal.
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
  /// Throws a [PositionSetupException] if it does not meet basic validity requirements.
  void validate({bool? ignoreImpossibleCheck}) {
    if (board.occupied.isEmpty) {
      throw PositionSetupException.empty;
    }
    if (board.kings.size != 2) {
      throw PositionSetupException.kings;
    }
    final ourKing = board.kingOf(turn);
    if (ourKing == null) {
      throw PositionSetupException.kings;
    }
    final otherKing = board.kingOf(turn.opposite);
    if (otherKing == null) {
      throw PositionSetupException.kings;
    }
    if (kingAttackers(otherKing, turn).isNotEmpty) {
      throw PositionSetupException.oppositeCheck;
    }
    if (SquareSet.backranks.isIntersected(board.pawns)) {
      throw PositionSetupException.pawnsOnBackrank;
    }
    final skipImpossibleCheck = ignoreImpossibleCheck ?? false;
    if (!skipImpossibleCheck) {
      _validateCheckers(ourKing);
    }
  }

  @override
  String toString() {
    return '$T(board: $board, turn: $turn, castles: $castles, halfmoves: $halfmoves, fullmoves: $fullmoves)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Position &&
            other.board == board &&
            other.pockets == pockets &&
            other.turn == turn &&
            other.castles == castles &&
            other.epSquare == epSquare &&
            other.halfmoves == halfmoves &&
            other.fullmoves == fullmoves;
  }

  @override
  int get hashCode => Object.hash(
        board,
        pockets,
        turn,
        castles,
        epSquare,
        halfmoves,
        fullmoves,
      );

  /// Checks if checkers are legal in this position.
  ///
  /// Throws a [PositionSetupException.impossibleCheck] if it does not meet validity
  /// requirements.
  void _validateCheckers(Square ourKing) {
    final checkers = kingAttackers(ourKing, turn.opposite);
    if (checkers.isNotEmpty) {
      if (epSquare != null) {
        // The pushed pawn must be the only checker, or it has uncovered
        // check by a single sliding piece.
        final pushedTo = epSquare!.xor(Square.a2);
        final pushedFrom = epSquare!.xor(Square.a4);
        if (checkers.moreThanOne ||
            (checkers.first != pushedTo &&
                board
                    .attacksTo(ourKing, turn.opposite,
                        occupied: board.occupied
                            .withoutSquare(pushedTo)
                            .withSquare(pushedFrom))
                    .isNotEmpty)) {
          throw PositionSetupException.impossibleCheck;
        }
      } else {
        // Multiple sliding checkers aligned with king.
        if (checkers.size > 2 ||
            (checkers.size == 2 &&
                ray(checkers.first!, checkers.last!).has(ourKing))) {
          throw PositionSetupException.impossibleCheck;
        }
      }
    }
  }

  String _makeSanWithoutSuffix(Move move) {
    String san = '';
    switch (move) {
      case NormalMove(from: final from, to: final to, promotion: final prom):
        final role = board.roleAt(from);
        if (role == null) return '--';
        if (role == Role.king &&
            (board.bySide(turn).has(to) || (to - from).abs() == 2)) {
          san = to > from ? 'O-O' : 'O-O-O';
        } else {
          final capture = board.occupied.has(to) ||
              (role == Role.pawn && from.file != to.file);
          if (role != Role.pawn) {
            san = role.uppercaseLetter;

            // Disambiguation
            SquareSet others;
            if (role == Role.king) {
              others = kingAttacks(to) & board.kings;
            } else if (role == Role.queen) {
              others = queenAttacks(to, board.occupied) & board.queens;
            } else if (role == Role.rook) {
              others = rookAttacks(to, board.occupied) & board.rooks;
            } else if (role == Role.bishop) {
              others = bishopAttacks(to, board.occupied) & board.bishops;
            } else {
              others = knightAttacks(to) & board.knights;
            }
            others = others.intersect(board.bySide(turn)).withoutSquare(from);

            if (others.isNotEmpty) {
              final ctx = _makeContext();
              for (final from in others.squares) {
                if (!_legalMovesOf(from, context: ctx).has(to)) {
                  others = others.withoutSquare(from);
                }
              }
              if (others.isNotEmpty) {
                bool row = false;
                bool column =
                    others.isIntersected(SquareSet.fromRank(from.rank));
                if (others.isIntersected(SquareSet.fromFile(from.file))) {
                  row = true;
                } else {
                  column = true;
                }
                if (column) {
                  san += from.file.name;
                }
                if (row) {
                  san += from.rank.name;
                }
              }
            }
          } else if (capture) {
            san = from.file.name;
          }

          if (capture) san += 'x';
          san += to.name;
          if (prom != null) {
            san += '=${prom.uppercaseLetter}';
          }
        }
      case DropMove(role: final role, to: final to):
        if (role != Role.pawn) san = role.uppercaseLetter;
        san += '@${to.name}';
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

    SquareSet pseudo;
    SquareSet? legalEpSquare;
    if (piece.role == Role.pawn) {
      pseudo = pawnAttacks(turn, square) & board.bySide(turn.opposite);
      final delta = turn == Side.white ? 8 : -8;
      final step = square + delta;
      if (0 <= step && step < 64 && !board.occupied.has(Square(step))) {
        pseudo = pseudo.withSquare(Square(step));
        final canDoubleStep =
            turn == Side.white ? square < Square.a3 : square >= Square.a7;
        final doubleStep = step + delta;
        if (canDoubleStep && !board.occupied.has(Square(doubleStep))) {
          pseudo = pseudo.withSquare(Square(doubleStep));
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
    if (ctx.king != null) {
      if (piece.role == Role.king) {
        final occ = board.occupied.withoutSquare(square);
        for (final to in pseudo.squares) {
          if (kingAttackers(to, turn.opposite, occupied: occ).isNotEmpty) {
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
        pseudo = pseudo & between(checker, ctx.king!).withSquare(checker);
      }

      if (ctx.blockers.has(square)) {
        pseudo = pseudo & ray(square, ctx.king!);
      }
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
        .intersect(board.bySide(turn.opposite));
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

    final kingTo = kingCastlesTo(turn, side);
    final kingPath = between(king, kingTo);
    final occ = board.occupied.withoutSquare(king);
    for (final sq in kingPath.squares) {
      if (kingAttackers(sq, turn.opposite, occupied: occ).isNotEmpty) {
        return SquareSet.empty;
      }
    }
    final rookTo = rookCastlesTo(turn, side);
    final after = board.occupied
        .toggleSquare(king)
        .toggleSquare(rook)
        .toggleSquare(rookTo);
    if (kingAttackers(kingTo, turn.opposite, occupied: after).isNotEmpty) {
      return SquareSet.empty;
    }
    return SquareSet.fromSquare(rook);
  }

  bool _canCaptureEp(Square pawn) {
    if (epSquare == null) return false;
    if (!pawnAttacks(turn, pawn).has(epSquare!)) return false;
    final king = board.kingOf(turn);
    if (king == null) return true;
    final captured = Square(epSquare! + (turn == Side.white ? -8 : 8));
    final occupied = board.occupied
        .toggleSquare(pawn)
        .toggleSquare(epSquare!)
        .toggleSquare(captured);
    return !board
        .attacksTo(king, turn.opposite, occupied: occupied)
        .isIntersected(occupied);
  }

  /// Detects if a move is a castling move.
  ///
  /// Returns the [CastlingSide] or `null` if the move is not a castling move.
  CastlingSide? _getCastlingSide(Move move) {
    if (move case NormalMove(from: final from, to: final to)) {
      if (!board.kings.has(from)) return null;
      if (turn == Side.white && move.to > Square.h1) return null;
      if (turn == Side.black && move.to < Square.a8) return null;
      final delta = to - from;
      if (delta.abs() != 2 && !board.bySide(turn).has(to)) {
        return null;
      }
      return delta > 0 ? CastlingSide.king : CastlingSide.queen;
    }
    return null;
  }

  Square? _legalEpSquare() {
    if (epSquare == null) return null;
    final ourPawns = board.piecesOf(turn, Role.pawn);
    final candidates = ourPawns & pawnAttacks(turn.opposite, epSquare!);
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
abstract class Chess extends Position<Chess> {
  @override
  Rule get rule => Rule.chess;

  /// Creates a new [Chess] position.
  const factory Chess({
    required Board board,
    Pockets? pockets,
    required Side turn,
    required Castles castles,
    Square? epSquare,
    required int halfmoves,
    required int fullmoves,
  }) = _Chess;

  const Chess._({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
  });

  /// Sets up a playable [Chess] position.
  ///
  /// Throws a [PositionSetupException] if the [Setup] does not meet basic validity
  /// requirements.
  /// Optionnaly pass [ignoreImpossibleCheck] if you want to skip that requirement.
  factory Chess.fromSetup(Setup setup, {bool? ignoreImpossibleCheck}) {
    final pos = Chess(
      board: setup.board,
      pockets: setup.pockets,
      turn: setup.turn,
      castles: Castles.fromSetup(setup),
      epSquare: _validEpSquare(setup),
      halfmoves: setup.halfmoves,
      fullmoves: setup.fullmoves,
    );
    pos.validate(ignoreImpossibleCheck: ignoreImpossibleCheck);
    return pos;
  }

  /// The initial position of a standard chess game.
  static const initial = Chess(
    board: Board.standard,
    turn: Side.white,
    castles: Castles.standard,
    halfmoves: 0,
    fullmoves: 1,
  );

  @override
  bool get isVariantEnd => false;

  @override
  Outcome? get variantOutcome => null;

  @override
  Chess copyWith({
    Board? board,
    Pockets? pockets,
    Side? turn,
    Castles? castles,
    Square? epSquare,
    int? halfmoves,
    int? fullmoves,
  });
}

/// A variant of chess where you lose all your pieces or get stalemated to win.
@immutable
abstract class Antichess extends Position<Antichess> {
  @override
  Rule get rule => Rule.antichess;

  /// Creates a new [Antichess] position.
  const factory Antichess({
    required Board board,
    Pockets? pockets,
    required Side turn,
    required Castles castles,
    Square? epSquare,
    required int halfmoves,
    required int fullmoves,
  }) = _Antichess;

  const Antichess._({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
  });

  /// Sets up a playable [Antichess] position.
  ///
  /// Throws a [PositionSetupException] if the [Setup] does not meet basic validity
  /// requirements.
  /// Optionnaly pass [ignoreImpossibleCheck] if you want to skip that
  /// requirement.
  factory Antichess.fromSetup(Setup setup, {bool? ignoreImpossibleCheck}) {
    final pos = Antichess(
      board: setup.board,
      pockets: setup.pockets,
      turn: setup.turn,
      castles: Castles.empty,
      epSquare: _validEpSquare(setup),
      halfmoves: setup.halfmoves,
      fullmoves: setup.fullmoves,
    );
    pos.validate(ignoreImpossibleCheck: ignoreImpossibleCheck);
    return pos;
  }

  /// The initial position of an Antichess game.
  static const initial = Antichess(
    board: Board.standard,
    turn: Side.white,
    castles: Castles.empty,
    halfmoves: 0,
    fullmoves: 1,
  );

  @override
  bool get isVariantEnd => board.bySide(turn).isEmpty;

  @override
  Outcome? get variantOutcome {
    if (isVariantEnd || isStalemate) {
      return Outcome(winner: turn);
    }
    return null;
  }

  @override
  void validate({bool? ignoreImpossibleCheck}) {
    if (board.occupied.isEmpty) {
      throw PositionSetupException.empty;
    }
    if (SquareSet.backranks.isIntersected(board.pawns)) {
      throw PositionSetupException.pawnsOnBackrank;
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
        pawnAttacks(turn.opposite, epSquare!)
            .isIntersected(board.piecesOf(turn, Role.pawn))) {
      return ctx.copyWith(mustCapture: true);
    }
    final enemy = board.bySide(turn.opposite);
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
    final enemy = board.bySide(turn.opposite);
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
    if (board.bySide(side.opposite).isEmpty) return true;
    if (board.occupied == board.bishops) {
      final weSomeOnLight =
          board.bySide(side).isIntersected(SquareSet.lightSquares);
      final weSomeOnDark =
          board.bySide(side).isIntersected(SquareSet.darkSquares);
      final theyAllOnDark =
          board.bySide(side.opposite).isDisjoint(SquareSet.lightSquares);
      final theyAllOnLight =
          board.bySide(side.opposite).isDisjoint(SquareSet.darkSquares);
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
}

/// A variant of chess where captures cause an explosion to the surrounding pieces.
@immutable
abstract class Atomic extends Position<Atomic> {
  @override
  Rule get rule => Rule.atomic;

  const factory Atomic({
    required Board board,
    Pockets? pockets,
    required Side turn,
    required Castles castles,
    Square? epSquare,
    required int halfmoves,
    required int fullmoves,
  }) = _Atomic;

  const Atomic._({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
  });

  /// Sets up a playable [Atomic] position.
  ///
  /// Throws a [PositionSetupException] if the [Setup] does not meet basic validity
  /// requirements.
  /// Optionnaly pass [ignoreImpossibleCheck] if you want to skip that
  /// requirement.
  factory Atomic.fromSetup(Setup setup, {bool? ignoreImpossibleCheck}) {
    final pos = Atomic(
      board: setup.board,
      pockets: setup.pockets,
      turn: setup.turn,
      castles: Castles.fromSetup(setup),
      epSquare: _validEpSquare(setup),
      halfmoves: setup.halfmoves,
      fullmoves: setup.fullmoves,
    );
    pos.validate(ignoreImpossibleCheck: ignoreImpossibleCheck);
    return pos;
  }

  /// The initial position of an Atomic game.
  static const initial = Atomic(
    board: Board.standard,
    turn: Side.white,
    castles: Castles.standard,
    halfmoves: 0,
    fullmoves: 1,
  );

  @override
  bool get isVariantEnd => variantOutcome != null;

  @override
  Outcome? get variantOutcome {
    for (final color in Side.values) {
      if (board.piecesOf(color, Role.king).isEmpty) {
        return Outcome(winner: color.opposite);
      }
    }
    return null;
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
  /// Throws a [PositionSetupException] if it does not meet basic validity requirements.
  @override
  void validate({bool? ignoreImpossibleCheck}) {
    if (board.occupied.isEmpty) {
      throw PositionSetupException.empty;
    }
    if (board.kings.size > 2) {
      throw PositionSetupException.kings;
    }
    final otherKing = board.kingOf(turn.opposite);
    if (otherKing == null) {
      throw PositionSetupException.kings;
    }
    if (kingAttackers(otherKing, turn).isNotEmpty) {
      throw PositionSetupException.oppositeCheck;
    }
    if (SquareSet.backranks.isIntersected(board.pawns)) {
      throw PositionSetupException.pawnsOnBackrank;
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
      return newPos.copyWith(board: newBoard, castles: newCastles);
    } else {
      return newPos;
    }
  }

  /// Tests if a [Side] has insufficient winning material.
  @override
  bool hasInsufficientMaterial(Side side) {
    // Remaining material does not matter if the enemy king is already
    // exploded.
    if (board.piecesOf(side.opposite, Role.king).isEmpty) return false;

    // Bare king cannot mate.
    if (board.bySide(side).diff(board.kings).isEmpty) return true;

    // As long as the enemy king is not alone, there is always a chance their
    // own pieces explode next to it.
    if (board.bySide(side.opposite).diff(board.kings).isNotEmpty) {
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
  Atomic copyWith({
    Board? board,
    Pockets? pockets,
    Side? turn,
    Castles? castles,
    Square? epSquare,
    int? halfmoves,
    int? fullmoves,
  });
}

/// A variant where captured pieces can be dropped back on the board instead of moving a piece.
@immutable
abstract class Crazyhouse extends Position<Crazyhouse> {
  @override
  Rule get rule => Rule.crazyhouse;

  /// Creates a new [Crazyhouse] position.
  const factory Crazyhouse({
    required Board board,
    Pockets? pockets,
    required Side turn,
    required Castles castles,
    Square? epSquare,
    required int halfmoves,
    required int fullmoves,
  }) = _Crazyhouse;

  const Crazyhouse._({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
  });

  /// Sets up a playable [Crazyhouse] position.
  ///
  /// Throws a [PositionSetupException] if the [Setup] does not meet basic validity
  /// requirements.
  /// Optionnaly pass [ignoreImpossibleCheck] if you want to skip that
  /// requirement.
  factory Crazyhouse.fromSetup(Setup setup, {bool? ignoreImpossibleCheck}) {
    final pos = Crazyhouse(
      board: setup.board.withPromoted(setup.board.promoted
          .intersect(setup.board.occupied)
          .diff(setup.board.kings)
          .diff(setup.board.pawns)),
      pockets: setup.pockets ?? Pockets.empty,
      turn: setup.turn,
      castles: Castles.fromSetup(setup),
      epSquare: _validEpSquare(setup),
      halfmoves: setup.halfmoves,
      fullmoves: setup.fullmoves,
    );
    pos.validate(ignoreImpossibleCheck: ignoreImpossibleCheck);
    return pos;
  }

  /// The initial position of a Crazyhouse game.
  static const initial = Crazyhouse(
    board: Board.standard,
    pockets: Pockets.empty,
    turn: Side.white,
    castles: Castles.standard,
    halfmoves: 0,
    fullmoves: 1,
  );

  @override
  bool get isVariantEnd => false;

  @override
  Outcome? get variantOutcome => null;

  @override
  void validate({bool? ignoreImpossibleCheck}) {
    super.validate(ignoreImpossibleCheck: ignoreImpossibleCheck);
    if (pockets == null) {
      throw PositionSetupException.variant;
    } else {
      if (pockets!.count(Role.king) > 0) {
        throw PositionSetupException.kings;
      }
      if (pockets!.size + board.occupied.size > 64) {
        throw PositionSetupException.variant;
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
  Crazyhouse copyWith({
    Board? board,
    Pockets? pockets,
    Side? turn,
    Castles? castles,
    Square? epSquare,
    int? halfmoves,
    int? fullmoves,
  });
}

/// A variant similar to standard chess, where you win by putting your king on the center
/// of the board.
@immutable
abstract class KingOfTheHill extends Position<KingOfTheHill> {
  @override
  Rule get rule => Rule.kingofthehill;

  /// Creates a new [KingOfTheHill] position.
  const factory KingOfTheHill({
    required Board board,
    Pockets? pockets,
    required Side turn,
    required Castles castles,
    Square? epSquare,
    required int halfmoves,
    required int fullmoves,
  }) = _KingOfTheHill;

  const KingOfTheHill._({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
  });

  /// Sets up a playable [KingOfTheHill] position.
  ///
  /// Throws a [PositionSetupException] if the [Setup] does not meet basic validity
  /// requirements.
  /// Optionnaly pass [ignoreImpossibleCheck] if you want to skip that
  /// requirement.
  factory KingOfTheHill.fromSetup(Setup setup, {bool? ignoreImpossibleCheck}) {
    final pos = KingOfTheHill(
      board: setup.board,
      pockets: setup.pockets,
      turn: setup.turn,
      castles: Castles.fromSetup(setup),
      epSquare: _validEpSquare(setup),
      halfmoves: setup.halfmoves,
      fullmoves: setup.fullmoves,
    );
    pos.validate(ignoreImpossibleCheck: ignoreImpossibleCheck);
    return pos;
  }

  /// The initial position of a KingOfTheHill game.
  static const initial = KingOfTheHill(
    board: Board.standard,
    turn: Side.white,
    castles: Castles.standard,
    halfmoves: 0,
    fullmoves: 1,
  );

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

  @override
  bool hasInsufficientMaterial(Side side) => false;

  @override
  KingOfTheHill copyWith({
    Board? board,
    Pockets? pockets,
    Side? turn,
    Castles? castles,
    Square? epSquare,
    int? halfmoves,
    int? fullmoves,
  });
}

/// A variant similar to standard chess, where you can win if you put your opponent king
/// into the third check.
@immutable
abstract class ThreeCheck extends Position<ThreeCheck> {
  @override
  Rule get rule => Rule.threecheck;

  /// Creates a new [ThreeCheck] position.
  const factory ThreeCheck({
    required Board board,
    Pockets? pockets,
    required Side turn,
    required Castles castles,
    Square? epSquare,
    required int halfmoves,
    required int fullmoves,
    required (int, int) remainingChecks,
  }) = _ThreeCheck;

  const ThreeCheck._({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
    required this.remainingChecks,
  });

  /// Set up a playable [ThreeCheck] position.
  ///
  /// Throws a [PositionSetupException] if the [Setup] does not meet basic validity
  /// requirements.
  /// Optionnaly pass a `ignoreImpossibleCheck` boolean if you want to skip that
  /// requirement.
  factory ThreeCheck.fromSetup(Setup setup, {bool? ignoreImpossibleCheck}) {
    if (setup.remainingChecks == null) {
      throw PositionSetupException.variant;
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

  /// Number of remainingChecks for white (`item1`) and black (`item2`).
  final (int, int) remainingChecks;

  /// The initial position of a ThreeCheck game.
  static const initial = ThreeCheck(
    board: Board.standard,
    turn: Side.white,
    castles: Castles.standard,
    halfmoves: 0,
    fullmoves: 1,
    remainingChecks: _defaultRemainingChecks,
  );

  static const _defaultRemainingChecks = (3, 3);

  @override
  bool get isVariantEnd => remainingChecks.$1 <= 0 || remainingChecks.$2 <= 0;

  @override
  Outcome? get variantOutcome {
    final (white, black) = remainingChecks;
    if (white <= 0) {
      return Outcome.whiteWins;
    }
    if (black <= 0) {
      return Outcome.blackWins;
    }
    return null;
  }

  @override
  String get fen {
    return Setup(
      board: board,
      turn: turn,
      castlingRights: castles.castlingRights,
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
      final (whiteChecks, blackChecks) = remainingChecks;
      return newPos.copyWith(
          remainingChecks: turn == Side.white
              ? (math.max(whiteChecks - 1, 0), blackChecks)
              : (whiteChecks, math.max(blackChecks - 1, 0)));
    } else {
      return newPos;
    }
  }

  @override
  ThreeCheck copyWith({
    Board? board,
    Pockets? pockets,
    Side? turn,
    Castles? castles,
    Square? epSquare,
    int? halfmoves,
    int? fullmoves,
    (int, int)? remainingChecks,
  });
}

/// A variant where the goal is to put your king on the eigth rank.
@immutable
abstract class RacingKings extends Position<RacingKings> {
  @override
  Rule get rule => Rule.racingKings;

  /// Creates a new [RacingKings] position.
  const factory RacingKings({
    required Board board,
    Pockets? pockets,
    required Side turn,
    required Castles castles,
    Square? epSquare,
    required int halfmoves,
    required int fullmoves,
  }) = _RacingKings;

  const RacingKings._({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
  });

  /// Sets up a playable [RacingKings] position.
  ///
  /// Throws a [PositionSetupException] if the [Setup] does not meet basic validity
  /// requirements.
  /// Optionnaly pass [ignoreImpossibleCheck] if you want to skip that
  /// requirement.
  factory RacingKings.fromSetup(Setup setup, {bool? ignoreImpossibleCheck}) {
    final pos = RacingKings(
      board: setup.board,
      turn: setup.turn,
      castles: Castles.empty,
      halfmoves: setup.halfmoves,
      fullmoves: setup.fullmoves,
    );
    pos.validate(ignoreImpossibleCheck: ignoreImpossibleCheck);
    return pos;
  }

  /// The initial position of a RacingKings game.
  static const initial = RacingKings(
    board: Board.racingKings,
    turn: Side.white,
    castles: Castles.empty,
    halfmoves: 0,
    fullmoves: 1,
  );

  static const goal = SquareSet.fromRank(Rank.eighth);

  bool get blackCanReachGoal {
    final blackKing = board.kingOf(Side.black);
    return blackKing != null &&
        kingAttacks(blackKing).intersect(goal).squares.where((square) {
          // Check whether this king move is legal
          final context = _Context(
            isVariantEnd: false,
            mustCapture: false,
            king: blackKing,
            blockers: _sliderBlockers(blackKing),
            checkers: checkers,
          );
          final legalMoves = _legalMovesOf(blackKing, context: context);
          return legalMoves.has(square);
        }).isNotEmpty;
  }

  bool get blackInGoal =>
      board.black.intersect(goal).intersect(board.kings).isNotEmpty;
  bool get whiteInGoal =>
      board.white.intersect(goal).intersect(board.kings).isNotEmpty;

  @override
  SquareSet _legalMovesOf(Square square, {_Context? context}) =>
      SquareSet.fromSquares(super
          ._legalMovesOf(square, context: context)
          .squares
          .where((to) =>
              !playUnchecked(NormalMove(from: square, to: to)).isCheck));

  @override
  bool isLegal(Move move) =>
      !playUnchecked(move).isCheck && super.isLegal(move);

  @override
  bool get isVariantEnd {
    if (!whiteInGoal && !blackInGoal) {
      return false;
    }
    if (blackInGoal || !blackCanReachGoal) {
      return true;
    }
    return false;
  }

  @override
  Outcome? get variantOutcome {
    if (!isVariantEnd) return null;
    if (whiteInGoal && blackInGoal) return Outcome.draw;
    // If white is in the goal, check whether
    // black can reach the goal. If not, then
    // white wins
    if (whiteInGoal && !blackCanReachGoal) return Outcome.whiteWins;
    // If black is the only side in the goal
    // then black wins
    if (blackInGoal) return Outcome.blackWins;

    return Outcome.draw;
  }

  @override
  bool hasInsufficientMaterial(Side side) => false;

  @override
  RacingKings playUnchecked(Move move) =>
      super.playUnchecked(move) as RacingKings;

  @override
  RacingKings copyWith({
    Board? board,
    Pockets? pockets,
    Side? turn,
    Castles? castles,
    Square? epSquare,
    int? halfmoves,
    int? fullmoves,
  });
}

/// A variant where white has 36 pawns and black needs to destroy the Horde to win.
@immutable
abstract class Horde extends Position<Horde> {
  @override
  Rule get rule => Rule.horde;

  /// Creates a new [Horde] position.
  const factory Horde({
    required Board board,
    Pockets? pockets,
    required Side turn,
    required Castles castles,
    Square? epSquare,
    required int halfmoves,
    required int fullmoves,
  }) = _Horde;

  const Horde._({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
  });

  /// Sets up a playable [Horde] position.
  ///
  /// Throws a [PositionSetupException] if the [Setup] does not meet basic validity
  /// requirements.
  /// Optionnaly pass [ignoreImpossibleCheck] if you want to skip that
  /// requirement.
  factory Horde.fromSetup(Setup setup, {bool? ignoreImpossibleCheck}) {
    final pos = Horde(
      board: setup.board,
      turn: setup.turn,
      castles: Castles.fromSetup(setup),
      epSquare: _validEpSquare(setup),
      halfmoves: setup.halfmoves,
      fullmoves: setup.fullmoves,
    );
    pos.validate(ignoreImpossibleCheck: ignoreImpossibleCheck);
    return pos;
  }

  /// The initial position of the Horde variant.
  static const initial = Horde(
    board: Board.horde,
    turn: Side.white,
    castles: Castles.horde,
    halfmoves: 0,
    fullmoves: 1,
  );

  @override
  void validate({bool? ignoreImpossibleCheck}) {
    if (board.occupied.isEmpty) {
      throw PositionSetupException.empty;
    }

    if (board.kings.size != 1) {
      throw PositionSetupException.kings;
    }

    final otherKing = board.kingOf(turn.opposite);
    if (otherKing != null && kingAttackers(otherKing, turn).isNotEmpty) {
      throw PositionSetupException.oppositeCheck;
    }

    // white can have pawns on back rank
    if (SquareSet.backranks.isIntersected(board.black.intersect(board.pawns))) {
      throw PositionSetupException.pawnsOnBackrank;
    }

    final skipImpossibleCheck = ignoreImpossibleCheck ?? false;
    final ourKing = board.kingOf(turn);
    if (!skipImpossibleCheck && ourKing != null) {
      _validateCheckers(ourKing);
    }
  }

  // get the number of light or dark square bishops
  int _hordeBishops(Side side, SquareColor sqColor) {
    if (sqColor == SquareColor.light) {
      return board
          .piecesOf(side, Role.bishop)
          .intersect(SquareSet.lightSquares)
          .size;
    }
    // dark squares
    return board
        .piecesOf(side, Role.bishop)
        .intersect(SquareSet.darkSquares)
        .size;
  }

  SquareColor _hordeBishopColor(Side side) {
    if (_hordeBishops(side, SquareColor.light) >= 1) {
      return SquareColor.light;
    }
    return SquareColor.dark;
  }

  bool _hasBishopPair(Side side) {
    final bishops = board.piecesOf(side, Role.bishop);
    return bishops.isIntersected(SquareSet.darkSquares) &&
        bishops.isIntersected(SquareSet.lightSquares);
  }

  int _pieceOfRoleNot(int piecesNum, int rolePieces) => piecesNum - rolePieces;

  @override
  bool hasInsufficientMaterial(Side side) {
    // side with king can always win by capturing the horde
    if (board.piecesOf(side, Role.king).isNotEmpty) {
      return false;
    }

    // now color represents horde and color.opposite is pieces
    final hordeNum = board.piecesOf(side, Role.pawn).size +
        board.piecesOf(side, Role.rook).size +
        board.piecesOf(side, Role.queen).size +
        board.piecesOf(side, Role.knight).size +
        math.min(_hordeBishops(side, SquareColor.light), 2) +
        math.min(_hordeBishops(side, SquareColor.dark), 2);

    if (hordeNum == 0) {
      return true;
    }

    if (hordeNum >= 4) {
      // 4 or more pieces can always deliver mate.
      return false;
    }

    final hordeMap = board.materialCount(side);
    final hordeBishopColor = _hordeBishopColor(side);
    final piecesMap = board.materialCount(side.opposite);
    final piecesNum = board.bySide(side.opposite).size;

    if ((hordeMap[Role.pawn]! >= 1 || hordeMap[Role.queen]! >= 1) &&
        hordeNum >= 2) {
      // Pawns/queens are never insufficient material when paired with any other
      // piece (a pawn promotes to a queen and delivers mate).
      return false;
    }

    if (hordeMap[Role.rook]! >= 1 && hordeNum >= 2) {
      // A rook is insufficient material only when it is paired with a bishop
      // against a lone king. The horde can mate in any other case.
      // A rook on A1 and a bishop on C3 mate a king on B1 when there is a
      // friendly pawn/opposite-color-bishop/rook/queen on C2.
      // A rook on B8 and a bishop C3 mate a king on A1 when there is a friendly
      // knight on A2.
      return hordeNum == 2 &&
          hordeMap[Role.rook]! == 1 &&
          hordeMap[Role.bishop]! == 1 &&
          (_pieceOfRoleNot(
                  piecesNum, _hordeBishops(side.opposite, hordeBishopColor)) ==
              1);
    }

    if (hordeNum == 1) {
      if (piecesNum == 1) {
        // lone piece cannot mate a lone king
        return true;
      } else if (hordeMap[Role.queen] == 1) {
        // The horde has a lone queen.
        // A lone queen mates a king on A1 bounded by:
        //  -- a pawn/rook on A2
        //  -- two same color bishops on A2, B1
        // We ignore every other mating case, since it can be reduced to
        // the two previous cases (e.g. a black pawn on A2 and a black
        // bishop on B1).

        return !(piecesMap[Role.pawn]! >= 1 ||
            piecesMap[Role.rook]! >= 1 ||
            _hordeBishops(side.opposite, SquareColor.light) >= 2 ||
            _hordeBishops(side, SquareColor.dark) >= 2);
      } else if (hordeMap[Role.pawn] == 1) {
        // Promote the pawn to a queen or a knight and check whether white can mate.
        final pawnSquare = board.piecesOf(side, Role.pawn).last;

        final promoteToQueen = copyWith();
        promoteToQueen.board
            .setPieceAt(pawnSquare!, Piece(color: side, role: Role.queen));
        final promoteToKnight = copyWith();
        promoteToKnight.board
            .setPieceAt(pawnSquare, Piece(color: side, role: Role.knight));
        return promoteToQueen.hasInsufficientMaterial(side) &&
            promoteToKnight.hasInsufficientMaterial(side);
      } else if (hordeMap[Role.rook] == 1) {
        // A lone rook mates a king on A8 bounded by a pawn/rook on A7 and a
        // pawn/knight on B7. We ignore every other case, since it can be
        // reduced to the two previous cases.
        // (e.g. three pawns on A7, B7, C7)

        return !(piecesMap[Role.pawn]! >= 2 ||
            (piecesMap[Role.rook]! >= 1 && piecesMap[Role.pawn]! >= 1) ||
            (piecesMap[Role.rook]! >= 1 && piecesMap[Role.knight]! >= 1) ||
            (piecesMap[Role.pawn]! >= 1 && piecesMap[Role.knight]! >= 1));
      } else if (hordeMap[Role.bishop] == 1) {
        // horde has a lone bishop
        // The king can be mated on A1 if there is a pawn/opposite-color-bishop
        // on A2 and an opposite-color-bishop on B1.
        // If black has two or more pawns, white gets the benefit of the doubt;
        // there is an outside chance that white promotes its pawns to
        // opposite-color-bishops and selfmates theirself.
        // Every other case that the king is mated by the bishop requires that
        // black has two pawns or two opposite-color-bishop or a pawn and an
        // opposite-color-bishop.
        // For example a king on A3 can be mated if there is
        // a pawn/opposite-color-bishop on A4, a pawn/opposite-color-bishop on
        // B3, a pawn/bishop/rook/queen on A2 and any other piece on B2.

        return !(_hordeBishops(side.opposite, hordeBishopColor.opposite) >= 2 ||
            (_hordeBishops(side.opposite, hordeBishopColor.opposite) >= 1 &&
                piecesMap[Role.pawn]! >= 1) ||
            piecesMap[Role.pawn]! >= 2);
      } else if (hordeMap[Role.knight] == 1) {
        // horde has a lone knight
        // The king on A1 can be smother mated by a knight on C2 if there is
        // a pawn/knight/bishop on B2, a knight/rook on B1 and any other piece
        // on A2.
        // Moreover, when black has four or more pieces and two of them are
        // pawns, black can promote their pawns and selfmate theirself.

        return !(piecesNum >= 4 &&
            (piecesMap[Role.knight]! >= 2 ||
                piecesMap[Role.pawn]! >= 2 ||
                (piecesMap[Role.rook]! >= 1 && piecesMap[Role.knight]! >= 1) ||
                (piecesMap[Role.rook]! >= 1 && piecesMap[Role.bishop]! >= 1) ||
                (piecesMap[Role.knight]! >= 1 &&
                    piecesMap[Role.bishop]! >= 1) ||
                (piecesMap[Role.rook]! >= 1 && piecesMap[Role.pawn]! >= 1) ||
                (piecesMap[Role.knight]! >= 1 && piecesMap[Role.pawn]! >= 1) ||
                (piecesMap[Role.bishop]! >= 1 && piecesMap[Role.pawn]! >= 1) ||
                (_hasBishopPair(side.opposite) &&
                    piecesMap[Role.pawn]! >= 1)) &&
            (_hordeBishops(side.opposite, SquareColor.light) < 2 ||
                (_pieceOfRoleNot(piecesNum,
                        _hordeBishops(side.opposite, SquareColor.light)) >=
                    3)) &&
            (_hordeBishops(side.opposite, SquareColor.dark) < 2 ||
                (_pieceOfRoleNot(piecesNum,
                        _hordeBishops(side.opposite, SquareColor.dark)) >=
                    3)));
      }
    } else if (hordeNum == 2) {
      if (piecesNum == 1) {
        // two minor pieces cannot mate a lone king
        return true;
      } else if (hordeMap[Role.knight] == 2) {
        // A king on A1 is mated by two knights, if it is obstructed by a
        // pawn/bishop/knight on B2. On the other hand, if black only has
        // major pieces it is a draw.

        return piecesMap[Role.pawn]! +
                piecesMap[Role.bishop]! +
                piecesMap[Role.knight]! <
            1;
      } else if (_hasBishopPair(side)) {
        return !(piecesMap[Role.pawn]! >= 1 ||
            piecesMap[Role.bishop]! >= 1 ||
            (piecesMap[Role.knight]! >= 1 &&
                piecesMap[Role.rook]! + piecesMap[Role.queen]! >= 1));
      } else if (hordeMap[Role.bishop]! >= 1 && hordeMap[Role.knight]! >= 1) {
        // horde has a bishop and a knight
        return !(piecesMap[Role.pawn]! >= 1 ||
            _hordeBishops(side.opposite, hordeBishopColor.opposite) >= 1 ||
            (_pieceOfRoleNot(piecesNum,
                    _hordeBishops(side.opposite, hordeBishopColor)) >=
                3));
      } else {
        // The horde has two or more bishops on the same color.
        // White can only win if black has enough material to obstruct
        // the squares of the opposite color around the king.
        //
        // A king on A1 obstructed by a pawn/opposite-bishop/knight
        // on A2 and a opposite-bishop/knight on B1 is mated by two
        // bishops on B2 and C3. This position is theoretically
        // achievable even when black has two pawns or when they
        // have a pawn and an opposite color bishop.

        return !((piecesMap[Role.pawn]! >= 1 &&
                _hordeBishops(side.opposite, hordeBishopColor.opposite) >= 1) ||
            (piecesMap[Role.pawn]! >= 1 && piecesMap[Role.knight]! >= 1) ||
            (_hordeBishops(side.opposite, hordeBishopColor.opposite) >= 1 &&
                piecesMap[Role.knight]! >= 1) ||
            (_hordeBishops(side.opposite, hordeBishopColor.opposite) >= 2) ||
            piecesMap[Role.knight]! >= 2 ||
            piecesMap[Role.pawn]! >= 2);
      }
    } else if (hordeNum == 3) {
      // A king in the corner is mated by two knights and a bishop or three
      // knights or the bishop pair and a knight/bishop.

      if ((hordeMap[Role.knight] == 2 && hordeMap[Role.bishop] == 1) ||
          hordeMap[Role.knight] == 3 ||
          _hasBishopPair(side)) {
        return false;
      } else {
        return piecesNum == 1;
      }
    }

    return true;
  }

  @override
  Outcome? get variantOutcome {
    if (board.white.isEmpty) return Outcome.blackWins;

    return null;
  }

  @override
  bool get isVariantEnd => board.white.isEmpty;

  @override
  Horde playUnchecked(Move move) => super.playUnchecked(move) as Horde;

  @override
  Horde copyWith({
    Board? board,
    Pockets? pockets,
    Side? turn,
    Castles? castles,
    Square? epSquare,
    int? halfmoves,
    int? fullmoves,
  });
}

/// The outcome of a [Position]. No [winner] means a draw.
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
  bool operator ==(Object other) =>
      identical(this, other) || other is Outcome && winner == other.winner;

  @override
  int get hashCode => winner.hashCode;

  /// Create [Outcome] from string
  static Outcome? fromPgn(String? outcome) {
    if (outcome == '1/2-1/2') {
      return Outcome.draw;
    } else if (outcome == '1-0') {
      return Outcome.whiteWins;
    } else if (outcome == '0-1') {
      return Outcome.blackWins;
    } else {
      return null;
    }
  }

  /// Create PGN String out of [Outcome]
  static String toPgnString(Outcome? outcome) {
    if (outcome == null) {
      return '*';
    } else if (outcome.winner == Side.white) {
      return '1-0';
    } else if (outcome.winner == Side.black) {
      return '0-1';
    } else {
      return '1/2-1/2';
    }
  }
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

Square? _validEpSquare(Setup setup) {
  if (setup.epSquare == null) return null;
  final epRank = setup.turn == Side.white ? 5 : 2;
  final forward = setup.turn == Side.white ? 8 : -8;
  if (setup.epSquare!.rank != epRank) return null;
  if (setup.board.occupied.has(Square(setup.epSquare!.value + forward))) {
    return null;
  }
  final pawn = Square(setup.epSquare!.value - forward);
  if (!setup.board.pawns.has(pawn) ||
      !setup.board.bySide(setup.turn.opposite).has(pawn)) {
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
    SquareSet captureTargets = pos.board.bySide(pos.turn.opposite);
    if (pos.epSquare != null) {
      captureTargets = captureTargets.withSquare(pos.epSquare!);
    }
    pseudo = pseudo & captureTargets;
    final delta = pos.turn == Side.white ? 8 : -8;
    final step = square + delta;
    if (0 <= step && step < 64 && !pos.board.occupied.has(Square(step))) {
      pseudo = pseudo.withSquare(Square(step));
      final canDoubleStep =
          pos.turn == Side.white ? square < Square.a3 : square >= Square.a7;
      if (canDoubleStep && !pos.board.occupied.has(Square(step + delta))) {
        pseudo = pseudo.withSquare(Square(step + delta));
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

// -- copyWith implementations

class _Chess extends Chess {
  const _Chess({
    required super.board,
    required super.turn,
    required super.castles,
    required super.halfmoves,
    required super.fullmoves,
    super.pockets,
    super.epSquare,
  }) : super._();

  @override
  Chess copyWith({
    Board? board,
    Object? pockets = _uniqueObjectInstance,
    Side? turn,
    Castles? castles,
    Object? epSquare = _uniqueObjectInstance,
    int? halfmoves,
    int? fullmoves,
  }) {
    return Chess(
      board: board ?? this.board,
      pockets:
          pockets == _uniqueObjectInstance ? this.pockets : pockets as Pockets?,
      turn: turn ?? this.turn,
      castles: castles ?? this.castles,
      epSquare: epSquare == _uniqueObjectInstance
          ? this.epSquare
          : epSquare as Square?,
      halfmoves: halfmoves ?? this.halfmoves,
      fullmoves: fullmoves ?? this.fullmoves,
    );
  }
}

class _Antichess extends Antichess {
  const _Antichess({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
  }) : super._();

  @override
  Antichess copyWith({
    Board? board,
    Object? pockets = _uniqueObjectInstance,
    Side? turn,
    Castles? castles,
    Object? epSquare = _uniqueObjectInstance,
    int? halfmoves,
    int? fullmoves,
  }) {
    return Antichess(
      board: board ?? this.board,
      pockets:
          pockets == _uniqueObjectInstance ? this.pockets : pockets as Pockets?,
      turn: turn ?? this.turn,
      castles: castles ?? this.castles,
      epSquare: epSquare == _uniqueObjectInstance
          ? this.epSquare
          : epSquare as Square?,
      halfmoves: halfmoves ?? this.halfmoves,
      fullmoves: fullmoves ?? this.fullmoves,
    );
  }
}

class _Atomic extends Atomic {
  const _Atomic({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
  }) : super._();

  @override
  Atomic copyWith({
    Board? board,
    Object? pockets = _uniqueObjectInstance,
    Side? turn,
    Castles? castles,
    Object? epSquare = _uniqueObjectInstance,
    int? halfmoves,
    int? fullmoves,
  }) {
    return Atomic(
      board: board ?? this.board,
      pockets:
          pockets == _uniqueObjectInstance ? this.pockets : pockets as Pockets?,
      turn: turn ?? this.turn,
      castles: castles ?? this.castles,
      epSquare: epSquare == _uniqueObjectInstance
          ? this.epSquare
          : epSquare as Square?,
      halfmoves: halfmoves ?? this.halfmoves,
      fullmoves: fullmoves ?? this.fullmoves,
    );
  }
}

class _Crazyhouse extends Crazyhouse {
  const _Crazyhouse({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
  }) : super._();

  @override
  Crazyhouse copyWith({
    Board? board,
    Object? pockets = _uniqueObjectInstance,
    Side? turn,
    Castles? castles,
    Object? epSquare = _uniqueObjectInstance,
    int? halfmoves,
    int? fullmoves,
  }) {
    return Crazyhouse(
      board: board ?? this.board,
      pockets:
          pockets == _uniqueObjectInstance ? this.pockets : pockets as Pockets?,
      turn: turn ?? this.turn,
      castles: castles ?? this.castles,
      epSquare: epSquare == _uniqueObjectInstance
          ? this.epSquare
          : epSquare as Square?,
      halfmoves: halfmoves ?? this.halfmoves,
      fullmoves: fullmoves ?? this.fullmoves,
    );
  }
}

class _KingOfTheHill extends KingOfTheHill {
  const _KingOfTheHill({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
  }) : super._();

  @override
  KingOfTheHill copyWith({
    Board? board,
    Object? pockets = _uniqueObjectInstance,
    Side? turn,
    Castles? castles,
    Object? epSquare = _uniqueObjectInstance,
    int? halfmoves,
    int? fullmoves,
  }) {
    return KingOfTheHill(
      board: board ?? this.board,
      pockets:
          pockets == _uniqueObjectInstance ? this.pockets : pockets as Pockets?,
      turn: turn ?? this.turn,
      castles: castles ?? this.castles,
      epSquare: epSquare == _uniqueObjectInstance
          ? this.epSquare
          : epSquare as Square?,
      halfmoves: halfmoves ?? this.halfmoves,
      fullmoves: fullmoves ?? this.fullmoves,
    );
  }
}

class _ThreeCheck extends ThreeCheck {
  const _ThreeCheck({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
    required super.remainingChecks,
  }) : super._();

  @override
  ThreeCheck copyWith({
    Board? board,
    Object? pockets = _uniqueObjectInstance,
    Side? turn,
    Castles? castles,
    Object? epSquare = _uniqueObjectInstance,
    int? halfmoves,
    int? fullmoves,
    (int, int)? remainingChecks,
  }) {
    return ThreeCheck(
      board: board ?? this.board,
      pockets:
          pockets == _uniqueObjectInstance ? this.pockets : pockets as Pockets?,
      turn: turn ?? this.turn,
      castles: castles ?? this.castles,
      epSquare: epSquare == _uniqueObjectInstance
          ? this.epSquare
          : epSquare as Square?,
      halfmoves: halfmoves ?? this.halfmoves,
      fullmoves: fullmoves ?? this.fullmoves,
      remainingChecks: remainingChecks ?? this.remainingChecks,
    );
  }
}

class _RacingKings extends RacingKings {
  const _RacingKings({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
  }) : super._();

  @override
  RacingKings copyWith({
    Board? board,
    Object? pockets = _uniqueObjectInstance,
    Side? turn,
    Castles? castles,
    Object? epSquare = _uniqueObjectInstance,
    int? halfmoves,
    int? fullmoves,
  }) {
    return RacingKings(
      board: board ?? this.board,
      pockets:
          pockets == _uniqueObjectInstance ? this.pockets : pockets as Pockets?,
      turn: turn ?? this.turn,
      castles: castles ?? this.castles,
      epSquare: epSquare == _uniqueObjectInstance
          ? this.epSquare
          : epSquare as Square?,
      halfmoves: halfmoves ?? this.halfmoves,
      fullmoves: fullmoves ?? this.fullmoves,
    );
  }
}

class _Horde extends Horde {
  const _Horde({
    required super.board,
    super.pockets,
    required super.turn,
    required super.castles,
    super.epSquare,
    required super.halfmoves,
    required super.fullmoves,
  }) : super._();

  @override
  Horde copyWith({
    Board? board,
    Object? pockets = _uniqueObjectInstance,
    Side? turn,
    Castles? castles,
    Object? epSquare = _uniqueObjectInstance,
    int? halfmoves,
    int? fullmoves,
  }) {
    return Horde(
      board: board ?? this.board,
      pockets:
          pockets == _uniqueObjectInstance ? this.pockets : pockets as Pockets?,
      turn: turn ?? this.turn,
      castles: castles ?? this.castles,
      epSquare: epSquare == _uniqueObjectInstance
          ? this.epSquare
          : epSquare as Square?,
      halfmoves: halfmoves ?? this.halfmoves,
      fullmoves: fullmoves ?? this.fullmoves,
    );
  }
}

/// Unique object to use as a sentinel value in copyWith methods.
const _uniqueObjectInstance = Object();
