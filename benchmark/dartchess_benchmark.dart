import 'package:benchmark/benchmark.dart';
import 'package:dartchess/dartchess.dart';
import 'dart:io';

void main() {
  benchmark('parsePgn - kasparov-deep-blue', () {
    final String data =
        File('./data/kasparov-deep-blue-1997.pgn').readAsStringSync();

    PgnGame.parseMultiGamePgn(data);
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

  final pgn = [
    '[Event "Rated Bullet game"]',
    '[Site "https://lichess.org/P5VLFjXI"]',
    '[Date "2022.08.23"]',
    '[White "mutdpro"]',
    '[Black "DrNykterstein"]',
    '[Result "0-1"]',
    '[UTCDate "2022.08.23"]',
    '[UTCTime "18:14:25"]',
    '[WhiteElo "3201"]',
    '[BlackElo "3317"]',
    '[WhiteRatingDiff "-4"]',
    '[BlackRatingDiff "+4"]',
    '[WhiteTitle "GM"]',
    '[BlackTitle "GM"]',
    '[Variant "Standard"]',
    '[TimeControl "60+0"]',
    '[ECO "A46"]',
    '[Opening "Indian Defense: Spielmann-Indian"]',
    '[Termination "Normal"]',
    '[Annotator "lichess.org"]',
    '\n',
    '1. d4 Nf6 2. Nf3 c5 { A46 Indian Defense: Spielmann-Indian } 3. c3 d5 4. Bf4 Qb6 5. Qc2 cxd4 6. cxd4 Nc6 7. e3 g6?! { (-0.32 → 0.49) Inaccuracy. Bf5 was best. } (7... Bf5 8. Qb3 Qxb3 9. axb3 Nh5 10. Bg3 Bd7 11. Nc3 e6 12. Bb5) 8. Nc3 Bf5 9. Qb3 Qxb3 10. axb3 a6 11. Bb5?! { (0.99 → 0.31) Inaccuracy. Ne5 was best. } (11. Ne5) 11... Bd7 12. Ne5 Rc8 13. Nxd7 Kxd7 14. Be2?! { (0.48 → -0.43) Inaccuracy. Bxc6+ was best. } (14. Bxc6+ Rxc6) 14... e6 15. Kd2?! { (-0.42 → -1.25) Inaccuracy. g3 was best. } (15. g3 Bd6) 15... Bb4?! { (-1.25 → -0.32) Inaccuracy. Ne4+ was best. } (15... Ne4+ 16. Nxe4 dxe4 17. Rhc1 Bb4+ 18. Kd1 Na5 19. Rcb1 Nxb3 20. Ra4 a5 21. Be5 Rhg8 22. Bf6) 16. Bd3 Ne4+ 17. Bxe4 dxe4 18. Ke2 f5 19. d5? { (0.26 → -0.87) Mistake. Na4 was best. } (19. Na4) 19... Ne7 20. Rhd1 Nxd5 21. Nxd5 Rc2+ 22. Kf1 exd5 23. Rxd5+ Ke6 24. Rad1 Rhc8 25. Re5+ Kf6 26. g4 Rc1 27. g5+ Kf7 28. Rxc1?? { (-0.81 → -4.55) Blunder. Rd5 was best. } (28. Rd5) 28... Rxc1+ 29. Kg2 Rc5? { (-5.48 → -2.89) Mistake. Rd1 was best. } (29... Rd1) 30. Rxc5 Bxc5 31. Be5 Ke6 32. Bc3 Bd6 33. h4 f4 34. Kh3 Kf5 35. Bd4?? { (-1.40 → -4.51) Blunder. b4 was best. } (35. b4) 35... b5 36. Bb6 Be5 37. Bc5 a5 38. Bb6 a4 39. bxa4 bxa4 40. Bd4 fxe3 41. fxe3 Bxd4 42. exd4 Ke6 { White resigns. } 0-1'
  ].join('\n');

  final game = PgnGame.parsePgn(pgn);
  benchmark('makePgn', () {
    game.makePgn();
  }, iterations: 1);
}
