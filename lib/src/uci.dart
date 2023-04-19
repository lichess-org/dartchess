import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'models.dart';
import 'utils.dart';
// import 'node.dart';

part 'uci.freezed.dart';
part 'uci.g.dart';

/// Uniquely identify a node in a game tree in a concise way.
///
/// This is a port of `UciCharPair` from scalachess.
@Freezed(toStringOverride: false, copyWith: false)
class UciCharPair with _$UciCharPair {
  const factory UciCharPair(String a, String b) = _UciCharPair;
  const UciCharPair._();

  factory UciCharPair.fromUci(String uci) {
    final move = Move.fromUci(uci);
    if (move == null) {
      throw ArgumentError('Invalid uci $uci');
    }
    return UciCharPair.fromMove(move);
  }

  factory UciCharPair.fromMove(Move move) {
    if (move is DropMove) {
      final roles = [
        Role.queen,
        Role.rook,
        Role.bishop,
        Role.knight,
        Role.pawn
      ];
      return UciCharPair(
        String.fromCharCode(35 + move.to),
        String.fromCharCode(35 + 64 + 8 * 5 + roles.indexOf(move.role)),
      );
    } else if (move is NormalMove) {
      final roles = [
        Role.queen,
        Role.rook,
        Role.bishop,
        Role.knight,
        Role.king
      ];
      final b = move.promotion != null
          ? 35 + 64 + 8 * roles.indexOf(move.promotion!) + squareFile(move.to)
          : 35 + move.to;
      return UciCharPair(
        String.fromCharCode(35 + move.from),
        String.fromCharCode(b),
      );
    }

    throw ArgumentError('Invalid move type $move');
  }

  factory UciCharPair.fromJson(Map<String, dynamic> json) =>
      _$UciCharPairFromJson(json);

  @override
  String toString() => '$a$b';
}

/// Compact representation of a path to a game node made from concatenated
/// UciCharPair strings.
@Freezed(copyWith: false)
class UciPath with _$UciPath {
  const factory UciPath(String value) = _UciPath;
  const UciPath._();

  factory UciPath.fromId(UciCharPair id) => UciPath(id.toString());
  factory UciPath.fromIds(IList<UciCharPair> ids) =>
      UciPath(ids.map((id) => id.toString()).join());

  static const empty = UciPath('');

  UciPath operator +(UciCharPair id) => UciPath(value + id.toString());

  bool contains(UciPath other) => value.startsWith(other.value);

  int get size => value.length ~/ 2;

  UciCharPair? get head =>
      value.isEmpty ? null : UciCharPair(value[0], value[1]);

  UciCharPair? get last => value.isEmpty
      ? null
      : UciCharPair(value[value.length - 2], value[value.length - 1]);

  UciPath get tail =>
      value.isEmpty ? UciPath.empty : UciPath(value.substring(2));

  UciPath get penultimate => value.isEmpty
      ? UciPath.empty
      : UciPath(value.substring(0, value.length - 2));

  bool get isEmpty => value.isEmpty;

  factory UciPath.fromJson(Map<String, dynamic> json) =>
      _$UciPathFromJson(json);
}
