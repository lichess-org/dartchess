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
  @JsonKey(ignore: true)
  $UciCharPairCopyWith<UciCharPair> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UciCharPairCopyWith<$Res> {
  factory $UciCharPairCopyWith(
          UciCharPair value, $Res Function(UciCharPair) then) =
      _$UciCharPairCopyWithImpl<$Res, UciCharPair>;
  @useResult
  $Res call({String a, String b});
}

/// @nodoc
class _$UciCharPairCopyWithImpl<$Res, $Val extends UciCharPair>
    implements $UciCharPairCopyWith<$Res> {
  _$UciCharPairCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? a = null,
    Object? b = null,
  }) {
    return _then(_value.copyWith(
      a: null == a
          ? _value.a
          : a // ignore: cast_nullable_to_non_nullable
              as String,
      b: null == b
          ? _value.b
          : b // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_UciCharPairCopyWith<$Res>
    implements $UciCharPairCopyWith<$Res> {
  factory _$$_UciCharPairCopyWith(
          _$_UciCharPair value, $Res Function(_$_UciCharPair) then) =
      __$$_UciCharPairCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String a, String b});
}

/// @nodoc
class __$$_UciCharPairCopyWithImpl<$Res>
    extends _$UciCharPairCopyWithImpl<$Res, _$_UciCharPair>
    implements _$$_UciCharPairCopyWith<$Res> {
  __$$_UciCharPairCopyWithImpl(
      _$_UciCharPair _value, $Res Function(_$_UciCharPair) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? a = null,
    Object? b = null,
  }) {
    return _then(_$_UciCharPair(
      null == a
          ? _value.a
          : a // ignore: cast_nullable_to_non_nullable
              as String,
      null == b
          ? _value.b
          : b // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
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

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_UciCharPairCopyWith<_$_UciCharPair> get copyWith =>
      __$$_UciCharPairCopyWithImpl<_$_UciCharPair>(this, _$identity);

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
  @override
  @JsonKey(ignore: true)
  _$$_UciCharPairCopyWith<_$_UciCharPair> get copyWith =>
      throw _privateConstructorUsedError;
}

UciPath _$UciPathFromJson(Map<String, dynamic> json) {
  return _UciPath.fromJson(json);
}

/// @nodoc
mixin _$UciPath {
  String get value => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UciPathCopyWith<UciPath> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UciPathCopyWith<$Res> {
  factory $UciPathCopyWith(UciPath value, $Res Function(UciPath) then) =
      _$UciPathCopyWithImpl<$Res, UciPath>;
  @useResult
  $Res call({String value});
}

/// @nodoc
class _$UciPathCopyWithImpl<$Res, $Val extends UciPath>
    implements $UciPathCopyWith<$Res> {
  _$UciPathCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_value.copyWith(
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_UciPathCopyWith<$Res> implements $UciPathCopyWith<$Res> {
  factory _$$_UciPathCopyWith(
          _$_UciPath value, $Res Function(_$_UciPath) then) =
      __$$_UciPathCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String value});
}

/// @nodoc
class __$$_UciPathCopyWithImpl<$Res>
    extends _$UciPathCopyWithImpl<$Res, _$_UciPath>
    implements _$$_UciPathCopyWith<$Res> {
  __$$_UciPathCopyWithImpl(_$_UciPath _value, $Res Function(_$_UciPath) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$_UciPath(
      null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
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

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_UciPathCopyWith<_$_UciPath> get copyWith =>
      __$$_UciPathCopyWithImpl<_$_UciPath>(this, _$identity);

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
  @override
  @JsonKey(ignore: true)
  _$$_UciPathCopyWith<_$_UciPath> get copyWith =>
      throw _privateConstructorUsedError;
}
