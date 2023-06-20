Chess and chess variant rules written in dart for native platforms (does not support web).

## Features

- Completely immutable Position class
- Read and write FEN
- Read and write SAN
- Chess rules:
    - move making
    - legal moves generation
    - game end and outcome
    - insufficient material
    - setup validation
- Chess960 support
- Chess variants: Antichess, Atomic, Crazyhouse, KingOfTheHill, ThreeCheck
- PGN parser and writer
- Bitboards
- Attacks and rays using hyperbola quintessence

## Example

```dart
import 'package:dartchess/dartchess.dart';

final pos = Chess.fromSetup(Setup.parseFen('r1bqkbnr/ppp2Qpp/2np4/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4'));
assert(pos.isCheckmate == true);
```

## Additional information

This package was heavily inspired from:
- https://github.com/niklasf/chessops
- https://github.com/niklasf/shakmaty
