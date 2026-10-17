// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_stroke.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CanvasStroke _$CanvasStrokeFromJson(
  Map<String, dynamic> json,
) => _CanvasStroke(
  color: (json['color'] as num).toInt(),
  width: (json['width'] as num?)?.toDouble() ?? 4.0,
  cap: $enumDecodeNullable(_$StrokeCapEnumMap, json['cap']) ?? StrokeCap.butt,
  join:
      $enumDecodeNullable(_$StrokeJoinEnumMap, json['join']) ??
      StrokeJoin.miter,
  miterLimit: (json['miterLimit'] as num?)?.toDouble() ?? 4.0,
  dash:
      (json['dash'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ??
      const <double>[],
);

Map<String, dynamic> _$CanvasStrokeToJson(_CanvasStroke instance) =>
    <String, dynamic>{
      'color': instance.color,
      'width': instance.width,
      'cap': _$StrokeCapEnumMap[instance.cap]!,
      'join': _$StrokeJoinEnumMap[instance.join]!,
      'miterLimit': instance.miterLimit,
      'dash': instance.dash,
    };

const _$StrokeCapEnumMap = {
  StrokeCap.butt: 'butt',
  StrokeCap.square: 'square',
  StrokeCap.round: 'round',
};

const _$StrokeJoinEnumMap = {
  StrokeJoin.miter: 'miter',
  StrokeJoin.bevel: 'bevel',
  StrokeJoin.round: 'round',
};
