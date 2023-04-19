// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

SanMove _$SanMoveFromJson(Map<String, dynamic> json) {
  return _SanMove.fromJson(json);
}

/// @nodoc
mixin _$SanMove {
  String get san => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _sanMoveFromJson, toJson: _sanMoveToJson)
  Move get move => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
@JsonSerializable()
class _$_SanMove implements _SanMove {
  const _$_SanMove(this.san,
      @JsonKey(fromJson: _sanMoveFromJson, toJson: _sanMoveToJson) this.move);

  factory _$_SanMove.fromJson(Map<String, dynamic> json) =>
      _$$_SanMoveFromJson(json);

  @override
  final String san;
  @override
  @JsonKey(fromJson: _sanMoveFromJson, toJson: _sanMoveToJson)
  final Move move;

  @override
  String toString() {
    return 'SanMove(san: $san, move: $move)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_SanMove &&
            (identical(other.san, san) || other.san == san) &&
            (identical(other.move, move) || other.move == move));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, san, move);

  @override
  Map<String, dynamic> toJson() {
    return _$$_SanMoveToJson(
      this,
    );
  }
}

abstract class _SanMove implements SanMove {
  const factory _SanMove(
      final String san,
      @JsonKey(fromJson: _sanMoveFromJson, toJson: _sanMoveToJson)
          final Move move) = _$_SanMove;

  factory _SanMove.fromJson(Map<String, dynamic> json) = _$_SanMove.fromJson;

  @override
  String get san;
  @override
  @JsonKey(fromJson: _sanMoveFromJson, toJson: _sanMoveToJson)
  Move get move;
}
