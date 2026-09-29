import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';
import 'dart:io' as io;

void main() {
  group('Zobrist hash', () {
    test('polyglot reference values', () {
      const referenceValues = {
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1':
            '463b96181691fc9c',
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1':
            '823c9b50fd114196',
        'rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2':
            '0756b94461c50fb0',
        'rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR b KQkq - 0 2':
            '662fafb965db29d4',
        'rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3':
            '22a48b5a8e47ff78',
        'rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPPKPPP/RNBQ1BNR b kq - 1 3':
            '652a607ca3f242c1',
        'rnbq1bnr/ppp1pkpp/8/3pPp2/8/8/PPPPKPPP/RNBQ1BNR w - - 2 4':
            '00fdd303c946bdd9',
        'rnbqkbnr/p1pppppp/8/8/PpP4P/8/1P1PPPP1/RNBQKBNR b KQkq c3 0 3':
            '3c8123ea7b067637',
        'rnbqkbnr/p1pppppp/8/8/P6P/R1p5/1P1PPPP1/1NBQKBNR b Kkq - 1 4':
            '5c3f9b829b279560',
      };

      for (final entry in referenceValues.entries) {
        final pos = Chess.fromSetup(Setup.parseFen(entry.key));
        expect(humanReadableZobristHash(pos.zobristHash()), entry.value,
            reason: entry.key);
      }
    });

    test('variants are not distinguished', () {
      // Useful when indexing a table of opening names by Zobrist hash.
      final hash = Chess.initial.zobristHash();
      expect(Crazyhouse.initial.zobristHash(), hash);
      expect(ThreeCheck.initial.zobristHash(), hash);
      expect(KingOfTheHill.initial.zobristHash(), hash);
    });

    test('full pockets', () {
      // A pocket count that overflows into a new mask bit must still change
      // the hash: 8/8/8/7k/8/8/3K4/8[ppppppppppppppppnnnnbbbbrrrrqq] w - - 0 54
      const base = '8/8/8/7k/8/8/3K4/8';
      Position pocket(String pieces) =>
          Crazyhouse.fromSetup(Setup.parseFen('$base[$pieces] w - - 0 54'));

      expect(pocket('p' * 16).zobristHash(),
          isNot(pocket('p' * 15).zobristHash()));
      expect(pocket('P' * 16).zobristHash(),
          isNot(pocket('P' * 15).zobristHash()));
      expect(pocket('qq').zobristHash(), isNot(pocket('q').zobristHash()));
      expect(pocket('QQ').zobristHash(), isNot(pocket('Q').zobristHash()));
    });

    test('crazyhouse pockets and promoted pieces are hashed', () {
      // Cross-checked against shakmaty.
      const referenceValues = {
        '8/8/8/7k/8/8/3K4/8[] w - - 0 54': '1b6d5ea260a2adb8',
        '8/8/8/7k/8/8/3K4/8[ppppppppppppppppnnnnbbbbrrrrqq] w - - 0 54':
            '02df4d8c101db96c',
        '4q~2k/8/8/8/8/8/8/4K3[] w - - 0 1': '4c6b714d8d014dd8',
        '4q2k/8/8/8/8/8/8/4K3[] w - - 0 1': '2f0af694c0ecd4c6',
      };

      for (final entry in referenceValues.entries) {
        final pos = Crazyhouse.fromSetup(Setup.parseFen(entry.key));
        expect(humanReadableZobristHash(pos.zobristHash()), entry.value,
            reason: entry.key);
      }
    });

    test('remaining checks are hashed', () {
      // Cross-checked against shakmaty. The `+w+b` part counts the checks
      // already given, so `+0+0` must hash like the standard chess position.
      const referenceValues = {
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1 +0+0':
            '463b96181691fc9c',
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1 +1+0':
            'c604c9a8c4688332',
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1 +0+1':
            '5b5656f6775f7ca2',
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1 +2+3':
            '2cfdd15aad5a6c25',
      };

      for (final entry in referenceValues.entries) {
        final pos = ThreeCheck.fromSetup(Setup.parseFen(entry.key));
        expect(humanReadableZobristHash(pos.zobristHash()), entry.value,
            reason: entry.key);
      }
    });

    test('shakmaty reference games', () {
      // Reference values from shakmaty's `tests/zobrist.csv`, truncated to
      // their low 64 bits.
      const rules = {
        'chess': Rule.chess,
        'antichess': Rule.antichess,
        'atomic': Rule.atomic,
        'crazyhouse': Rule.crazyhouse,
        'horde': Rule.horde,
        'kingofthehill': Rule.kingofthehill,
        'racingkings': Rule.racingKings,
        '3check': Rule.threecheck,
      };

      final lines = io.File('test/resources/zobrist.csv').readAsLinesSync();
      expect(lines.first, 'variant,uci,zobrist');

      for (var i = 1; i < lines.length; i++) {
        final [variant, uci, zobrist] = lines[i].split(',');
        var pos = Position.initialPosition(rules[variant]!);
        for (final move in uci.isEmpty ? const <String>[] : uci.split(' ')) {
          pos = pos.playUnchecked(Move.parse(move)!);
        }
        expect(humanReadableZobristHash(pos.zobristHash()),
            zobrist.substring(zobrist.length - 16),
            reason: 'line ${i + 1}: $variant $uci');
      }
    });

    test('transpositions have the same hash', () {
      final pos = Chess.initial
          .play(NormalMove.fromUci('g1f3'))
          .play(NormalMove.fromUci('g8f6'))
          .play(NormalMove.fromUci('f3g1'))
          .play(NormalMove.fromUci('f6g8'));
      expect(pos.zobristHash(), Chess.initial.zobristHash());
    });

    test('en passant mode', () {
      // The en passant square is set, but no pawn can capture on it.
      final unreachable = Chess.fromSetup(Setup.parseFen(
          'rnbqkbnr/pppp1ppp/8/8/4p3/8/PPPPPPPP/RNBQKBNR w KQkq - 0 3'));
      final pushed = unreachable.play(NormalMove.fromUci('a2a4'));
      expect(pushed.epSquare, Square.a3);
      expect(pushed.epSquareOf(EnPassantMode.always), Square.a3);
      expect(pushed.epSquareOf(EnPassantMode.pseudoLegal), isNull);
      expect(pushed.epSquareOf(EnPassantMode.legal), isNull);
      expect(pushed.zobristHash(mode: EnPassantMode.always),
          isNot(pushed.zobristHash()));

      // Pinned pawn: pseudo-legal, but not legal.
      final pinned =
          Chess.fromSetup(Setup.parseFen('8/8/8/K2pP2q/8/8/8/3k4 w - d6 0 2'));
      expect(pinned.epSquareOf(EnPassantMode.always), Square.d6);
      expect(pinned.epSquareOf(EnPassantMode.pseudoLegal), Square.d6);
      expect(pinned.epSquareOf(EnPassantMode.legal), isNull);
      expect(pinned.zobristHash(mode: EnPassantMode.pseudoLegal),
          isNot(pinned.zobristHash()));
    });
  });
}
