import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';

void main() {
  group('File', () {
    test('File.values', () {
      expect(File.values.length, 8);
    });

    test('fromAlgebraic', () {
      expect(File.fromAlgebraic('a'), File.a);
      expect(File.fromAlgebraic('h'), File.h);
      expect(() => File.fromAlgebraic('i'), throwsFormatException);
    });

    test('offset', () {
      expect(File.a.offset(1), File.b);
      expect(File.h.offset(-1), File.g);
      expect(File.h.offset(1), null);
    });
  });

  group('Rank', () {
    test('Rank.values', () {
      expect(Rank.values.length, 8);
    });

    test('fromAlgebraic', () {
      expect(Rank.fromAlgebraic('1'), Rank.first);
      expect(Rank.fromAlgebraic('8'), Rank.eighth);
      expect(() => Rank.fromAlgebraic('9'), throwsFormatException);
    });

    test('offset', () {
      expect(Rank.first.offset(1), Rank.second);
      expect(Rank.eighth.offset(-1), Rank.seventh);
      expect(Rank.eighth.offset(1), null);
    });
  });

  group('Square', () {
    test('Square.values', () {
      expect(Square.values.length, 64);
    });

    test('fromAlgebraic', () {
      expect(Square.fromAlgebraic('a1'), Square.a1);
      expect(Square.fromAlgebraic('h8'), Square.h8);
      expect(Square.fromAlgebraic('e4'), Square.e4);
      expect(() => Square.fromAlgebraic('i1'), throwsFormatException);
    });

    test('offset', () {
      expect(Square.a1.offset(8), Square.a2);
      expect(Square.h8.offset(-8), Square.h7);
      expect(Square.h8.offset(1), null);
    });

    test('algebraicNotation', () {
      expect(Square.a1.algebraicNotation, 'a1');
      expect(Square.h8.algebraicNotation, 'h8');
    });

    test('coord', () {
      expect(Square.a1.coord, const Coord(0, 0));
      expect(Square.c6.coord, const Coord(2, 5));
      expect(Square.h8.coord, const Coord(7, 7));
    });
  });

  group('Coord', () {
    test('Coord.values', () {
      expect(Coord.values.length, 64);
    });

    test('square', () {
      expect(const Coord(0, 0).square, Square.a1);
      expect(const Coord(2, 5).square, Square.c6);
      expect(const Coord(7, 7).square, Square.h8);
    });
  });

  group('Move', () {
    test('fromUci', () {
      expect(Move.fromUci('a1a2'),
          const NormalMove(from: Square.a1, to: Square.a2));
      expect(
          Move.fromUci('h7h8q'),
          const NormalMove(
              from: Square.h7, to: Square.h8, promotion: Role.queen));
      expect(
          Move.fromUci('P@h1'), const DropMove(role: Role.pawn, to: Square.h1));
    });

    test('uci', () {
      expect(const DropMove(role: Role.queen, to: Square.b1).uci, 'Q@b1');
      expect(const NormalMove(from: Square.c1, to: Square.d1).uci, 'c1d1');
      expect(
          const NormalMove(
                  from: Square.a1, to: Square.a1, promotion: Role.knight)
              .uci,
          'a1a1n');
    });
  });
}
