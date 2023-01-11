import 'package:benchmark/benchmark.dart';
import 'package:dartchess/dartchess.dart';
import 'dart:io';

void main() {
  benchmark('parsePgn - kasparov-deep-blue', () {
    final String data =
        File('./data/kasparov-deep-blue-1997.pgn').readAsStringSync();

    parsePgn(data);
  }, iterations: 1);

  benchmark('perft', () {
    perft(Chess.initial, 4);
  }, iterations: 1);

  benchmark('valid fen moves', () {
    const fen = 'rn1qkb1r/pbp2ppp/1p2p3/3n4/8/2N2NP1/PP1PPPBP/R1BQ1RK1 b kq -';
    final pos = Chess.fromSetup(Setup.parseFen(fen));
    assert(pos.legalMoves.length == 20);
  }, iterations: 1);

  benchmark('play moves', () {
    const fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    final pos = Chess.fromSetup(Setup.parseFen(fen));
    pos.play(const NormalMove(from: 12, to: 28));
  }, iterations: 1);
}
