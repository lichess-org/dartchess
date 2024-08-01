import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';

void main() {
  group('File', () {
    test('File.values', () {
      expect(File.values.length, 8);
    });

    test('fromName', () {
      expect(File.fromName('a'), File.a);
      expect(File.fromName('h'), File.h);
      expect(() => File.fromName('i'), throwsFormatException);
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

    test('fromName', () {
      expect(Rank.fromName('1'), Rank.first);
      expect(Rank.fromName('8'), Rank.eighth);
      expect(() => Rank.fromName('9'), throwsFormatException);
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

    test('fromName', () {
      expect(Square.fromName('a1'), Square.a1);
      expect(Square.fromName('h8'), Square.h8);
      expect(Square.fromName('e4'), Square.e4);
      expect(() => Square.fromName('i1'), throwsFormatException);
      expect(() => Square.fromName('a9'), throwsFormatException);
      expect(() => Square.fromName('a11'), throwsFormatException);
    });

    test('parse', () {
      expect(Square.parse('a1'), Square.a1);
      expect(Square.parse('h8'), Square.h8);
      expect(Square.parse('e4'), Square.e4);
      expect(Square.parse('a9'), isNull);
      expect(Square.parse('i1'), isNull);
      expect(Square.parse('a11'), isNull);
    });

    test('offset', () {
      expect(Square.a1.offset(8), Square.a2);
      expect(Square.h8.offset(-8), Square.h7);
      expect(Square.h8.offset(1), null);
    });

    test('name', () {
      expect(Square.a1.name, 'a1');
      expect(Square.h8.name, 'h8');
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
    test('parse', () {
      expect(
          Move.parse('a1a2'), const NormalMove(from: Square.a1, to: Square.a2));
      expect(
          Move.parse('h7h8q'),
          const NormalMove(
              from: Square.h7, to: Square.h8, promotion: Role.queen));
      expect(
          Move.parse('P@h1'), const DropMove(role: Role.pawn, to: Square.h1));
    });

    test('NormalMove.fromUci', () {
      expect(NormalMove.fromUci('a1a2'),
          const NormalMove(from: Square.a1, to: Square.a2));
      expect(
          NormalMove.fromUci('h7h8q'),
          const NormalMove(
              from: Square.h7, to: Square.h8, promotion: Role.queen));
      expect(() => NormalMove.fromUci('P@h1'), throwsFormatException);
    });

    test('DropMove.fromUci', () {
      expect(DropMove.fromUci('P@h1'),
          const DropMove(role: Role.pawn, to: Square.h1));
      expect(() => DropMove.fromUci('a1a2'), throwsFormatException);
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
