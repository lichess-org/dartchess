// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_SanMove _$$_SanMoveFromJson(Map<String, dynamic> json) => _$_SanMove(
      json['san'] as String,
      _sanMoveFromJson(json['move'] as String),
    );

Map<String, dynamic> _$$_SanMoveToJson(_$_SanMove instance) =>
    <String, dynamic>{
      'san': instance.san,
      'move': _sanMoveToJson(instance.move),
    };
