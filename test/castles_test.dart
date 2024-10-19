import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';

void main() {
  group('Castles', () {
    test('implements hashCode/==', () {
      expect(Castles.standard, Castles.standard);
      expect(Castles.standard, isNot(Castles.empty));
      expect(
          Castles.standard,
          isNot(Castles.fromSetup(Setup.parseFen(
              'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQq - 0 1'))));
      expect(
          Castles.standard,
          isNot(Castles.fromSetup(Setup.parseFen(
              'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBRN w KQkq - 0 1'))));
    });
    test('fromSetup', () {
      final castles = Castles.fromSetup(Setup.standard);
      expect(castles.castlingRights, SquareSet.corners);
      expect(castles, Castles.standard);

      expect(castles.rookOf(Side.white, CastlingSide.queen), Square.a1);
      expect(castles.rookOf(Side.white, CastlingSide.king), Square.h1);
      expect(castles.rookOf(Side.black, CastlingSide.queen), Square.a8);
      expect(castles.rookOf(Side.black, CastlingSide.king), Square.h8);

      expect(castles.pathOf(Side.white, CastlingSide.queen).squares,
          equals([Square.b1, Square.c1, Square.d1]));
      expect(castles.pathOf(Side.white, CastlingSide.king).squares,
          equals([Square.f1, Square.g1]));
      expect(castles.pathOf(Side.black, CastlingSide.queen).squares,
          equals([Square.b8, Square.c8, Square.d8]));
      expect(castles.pathOf(Side.black, CastlingSide.king).squares,
          equals([Square.f8, Square.g8]));
    });

    test('discard rook', () {
      expect(Castles.standard.discardRookAt(Square.a4), Castles.standard);
      expect(
          Castles.standard.discardRookAt(Square.h1).rooksPositions[Side.white],
          IMap(const {CastlingSide.queen: Square.a1, CastlingSide.king: null}));
    });

    test('discard side', () {
      expect(
          Castles.standard.discardSide(Side.white).rooksPositions,
          equals(BySide({
            Side.white: ByCastlingSide(
              const {CastlingSide.queen: null, CastlingSide.king: null},
            ),
            Side.black: ByCastlingSide(
              const {
                CastlingSide.queen: Square.a8,
                CastlingSide.king: Square.h8,
              },
            )
          })));

      expect(
          Castles.standard.discardSide(Side.black).rooksPositions,
          equals(BySide({
            Side.white: ByCastlingSide(const {
              CastlingSide.queen: Square.a1,
              CastlingSide.king: Square.h1,
            }),
            Side.black: ByCastlingSide(
                const {CastlingSide.queen: null, CastlingSide.king: null})
          })));
    });
  });
}
