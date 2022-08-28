<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

Dart chess library for native platforms with an immutable API.

## Features

- Read and write FEN
- Chess rules:
    - move making
    - legal moves generation
    - game end and outcome
    - insufficient material
    - setup validation
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
