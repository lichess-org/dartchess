import 'package:benchmark/benchmark.dart';
import 'package:dartchess/dartchess.dart';
import 'dart:io';

void main() {
  benchmark('make fen from initial position', () {
    Chess.initial.fen;
  });

  final randomPos = Chess.fromSetup(
      Setup.parseFen('6k1/pp4pp/1np2r2/3pr3/3N4/5P2/1PP3PP/2KRR3 b - - 3 20'));
  benchmark('make fen from random position', () {
    randomPos.fen;
  });

  benchmark('parse san moves', () {
    const moves =
        'e4 Nc6 Bc4 e6 a3 g6 Nf3 Bg7 c3 Nge7 d3 O-O Be3 Na5 Ba2 b6 Qd2 Bb7 Bh6 d5 e5 d4 Bxg7 Kxg7 Qf4 Bxf3 Qxf3 dxc3 Nxc3 Nac6 Qf6+ Kg8 Rd1 Nd4 O-O c5 Ne4 Nef5 Rd2 Qxf6 Nxf6+ Kg7 Re1 h5 h3 Rad8 b4 Nh4 Re3 Nhf5 Re1 a5 bxc5 bxc5 Bc4 Ra8 Rb1 Nh4 Rdb2 Nc6 Rb7 Nxe5 Bxe6 Kxf6 Bd5 Nf5 R7b6+ Kg7 Bxa8 Rxa8 R6b3 Nd4 Rb7 Nxd3 Rd1 Ne2+ Kh2 Ndf4 Rdd7 Rf8 Ra7 c4 Rxa5 c3 Rc5 Ne6 Rc4 Ra8 a4 Rb8 a5 Rb2 a6 c2';
    Position pos = Chess.initial;
    for (final san in moves.split(' ')) {
      pos = pos.play(pos.parseSan(san)!);
    }
  });

  benchmark('parse san moves, play unchecked', () {
    const moves =
        'e4 Nc6 Bc4 e6 a3 g6 Nf3 Bg7 c3 Nge7 d3 O-O Be3 Na5 Ba2 b6 Qd2 Bb7 Bh6 d5 e5 d4 Bxg7 Kxg7 Qf4 Bxf3 Qxf3 dxc3 Nxc3 Nac6 Qf6+ Kg8 Rd1 Nd4 O-O c5 Ne4 Nef5 Rd2 Qxf6 Nxf6+ Kg7 Re1 h5 h3 Rad8 b4 Nh4 Re3 Nhf5 Re1 a5 bxc5 bxc5 Bc4 Ra8 Rb1 Nh4 Rdb2 Nc6 Rb7 Nxe5 Bxe6 Kxf6 Bd5 Nf5 R7b6+ Kg7 Bxa8 Rxa8 R6b3 Nd4 Rb7 Nxd3 Rd1 Ne2+ Kh2 Ndf4 Rdd7 Rf8 Ra7 c4 Rxa5 c3 Rc5 Ne6 Rc4 Ra8 a4 Rb8 a5 Rb2 a6 c2';
    Position pos = Chess.initial;
    for (final san in moves.split(' ')) {
      pos = pos.playUnchecked(pos.parseSan(san)!);
    }
  });

  final legalMovesPos = Chess.fromSetup(Setup.parseFen(
      'rn1qkb1r/pbp2ppp/1p2p3/3n4/8/2N2NP1/PP1PPPBP/R1BQ1RK1 b kq -'));
  benchmark('valid fen moves', () {
    legalMovesPos.legalMoves.length;
  });

  benchmark('algebraic legal moves', () {
    algebraicLegalMoves(legalMovesPos);
  });

  benchmark('parsePgn - kasparov-deep-blue', () {
    final String data =
        File('./data/kasparov-deep-blue-1997.pgn').readAsStringSync();

    PgnGame.parseMultiGamePgn(data);
  });

  final game = PgnGame.parsePgn(
      File('./data/lichess-bullet-game.pgn').readAsStringSync());
  benchmark('makePgn', () {
    game.makePgn();
  });

  benchmark('initial position perft at depth 5', () {
    perft(Chess.initial, 5);
  }, iterations: 1);
}
