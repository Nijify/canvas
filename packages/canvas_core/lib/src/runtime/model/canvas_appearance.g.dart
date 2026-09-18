// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_appearance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShadowEffect _$ShadowEffectFromJson(Map<String, dynamic> json) => ShadowEffect(
  id: json['id'] as String,
  enabled: json['enabled'] as bool? ?? true,
  offset: const Vec2Converter().fromJson(
    json['offset'] as Map<String, dynamic>,
  ),
  blurSigma: (json['blurSigma'] as num?)?.toDouble() ?? 0.0,
  color: (json['color'] as num).toInt(),
);

Map<String, dynamic> _$ShadowEffectToJson(ShadowEffect instance) =>
    <String, dynamic>{
      'id': instance.id,
      'enabled': instance.enabled,
      'offset': const Vec2Converter().toJson(instance.offset),
      'blurSigma': instance.blurSigma,
      'color': instance.color,
    };

_CanvasAppearance _$CanvasAppearanceFromJson(Map<String, dynamic> json) =>
    _CanvasAppearance(
      foreground: json['foreground'] == null
          ? const CanvasFill.solid(0xFF111111)
          : const CanvasFillConverter().fromJson(
              json['foreground'] as Map<String, dynamic>,
            ),
      underlays:
          (json['underlays'] as List<dynamic>?)
              ?.map(
                (e) => CanvasSourceUnderlay.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <CanvasSourceUnderlay>[],
    );

Map<String, dynamic> _$CanvasAppearanceToJson(_CanvasAppearance instance) =>
    <String, dynamic>{
      'foreground': const CanvasFillConverter().toJson(instance.foreground),
      'underlays': instance.underlays.map((e) => e.toJson()).toList(),
    };
