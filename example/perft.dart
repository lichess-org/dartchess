import 'package:dartchess/dartchess.dart';

void main() {
  final stopwatch = Stopwatch()..start();
  final depth = 4;
  perft(Chess.initial, depth);
  print(
      'initial position perft at depht $depth executed in ${stopwatch.elapsed.inMilliseconds} ms');
}
