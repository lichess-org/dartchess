import 'package:dartchess/dartchess.dart';
import 'package:test/test.dart';

void main() {
  group('Castles', () {
    test('Castles.fromSetup', () {
      final castles = Castles.fromSetup(Setup.standard);
      expect(castles.unmovedRooks, SquareSet.corners);
      expect(castles, Castles.standard);

      expect(castles.rookOf(Color.white, CastlingSide.queen), 0);
      expect(castles.rookOf(Color.white, CastlingSide.king), 7);
      expect(castles.rookOf(Color.black, CastlingSide.queen), 56);
      expect(castles.rookOf(Color.black, CastlingSide.king), 63);

      expect(castles.pathOf(Color.white, CastlingSide.queen).squares.toList(),
          [1, 2, 3]);
      expect(castles.pathOf(Color.white, CastlingSide.king).squares.toList(),
          [5, 6]);
      expect(castles.pathOf(Color.black, CastlingSide.queen).squares.toList(),
          [57, 58, 59]);
      expect(castles.pathOf(Color.black, CastlingSide.king).squares.toList(),
          [61, 62]);
    });

    test('discard rook', () {
      expect(Castles.standard.discardRookAt(24), Castles.standard);
      expect(
          Castles.standard.discardRookAt(7).rook[Color.white], Tuple2(0, null));
    });
  });
}
