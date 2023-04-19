// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'uci.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

UciCharPair _$UciCharPairFromJson(Map<String, dynamic> json) {
  return _UciCharPair.fromJson(json);
}

/// @nodoc
mixin _$UciCharPair {
  String get a => throw _privateConstructorUsedError;
  String get b => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
@JsonSerializable()
class _$_UciCharPair extends _UciCharPair {
  const _$_UciCharPair(this.a, this.b) : super._();

  factory _$_UciCharPair.fromJson(Map<String, dynamic> json) =>
      _$$_UciCharPairFromJson(json);

  @override
  final String a;
  @override
  final String b;

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_UciCharPair &&
            (identical(other.a, a) || other.a == a) &&
            (identical(other.b, b) || other.b == b));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, a, b);

  @override
  Map<String, dynamic> toJson() {
    return _$$_UciCharPairToJson(
      this,
    );
  }
}

abstract class _UciCharPair extends UciCharPair {
  const factory _UciCharPair(final String a, final String b) = _$_UciCharPair;
  const _UciCharPair._() : super._();

  factory _UciCharPair.fromJson(Map<String, dynamic> json) =
      _$_UciCharPair.fromJson;

  @override
  String get a;
  @override
  String get b;
}

UciPath _$UciPathFromJson(Map<String, dynamic> json) {
  return _UciPath.fromJson(json);
}

/// @nodoc
mixin _$UciPath {
  String get value => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
@JsonSerializable()
class _$_UciPath extends _UciPath {
  const _$_UciPath(this.value) : super._();

  factory _$_UciPath.fromJson(Map<String, dynamic> json) =>
      _$$_UciPathFromJson(json);

  @override
  final String value;

  @override
  String toString() {
    return 'UciPath(value: $value)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_UciPath &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  Map<String, dynamic> toJson() {
    return _$$_UciPathToJson(
      this,
    );
  }
}

abstract class _UciPath extends UciPath {
  const factory _UciPath(final String value) = _$_UciPath;
  const _UciPath._() : super._();

  factory _UciPath.fromJson(Map<String, dynamic> json) = _$_UciPath.fromJson;

  @override
  String get value;
}
