Dart chess library for native platforms with an immutable API.

## Features

- Read and write FEN
- Chess rules:
    - move making
    - legal moves generation
    - game end and outcome
    - insufficient material
    - setup validation
- Chess960 support
- Chess variants: Antichess, Atomic, KingOfTheHill
- Attacks and rays using hyperbola quintessence
- Immutability: all the classes are immutable.

## Example

```dart
import 'package:dartchess/dartchess.dart';

final pos = Chess.fromSetup(Setup.parseFen('r1bqkbnr/ppp2Qpp/2np4/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4'));
assert(pos.isCheckmate == true);
```

## Additional information

This package code was heavily inspired from:
- https://github.com/niklasf/chessops
- https://github.com/niklasf/shakmaty
