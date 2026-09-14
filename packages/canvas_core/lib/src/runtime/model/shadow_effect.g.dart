// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shadow_effect.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShadowEffect _$ShadowEffectFromJson(Map<String, dynamic> json) =>
    _ShadowEffect(
      id: json['id'] as String,
      enabled: json['enabled'] as bool? ?? true,
      offset: const Vec2Converter().fromJson(
        json['offset'] as Map<String, dynamic>,
      ),
      blurSigma: (json['blurSigma'] as num?)?.toDouble() ?? 0.0,
      color: (json['color'] as num).toInt(),
    );

Map<String, dynamic> _$ShadowEffectToJson(_ShadowEffect instance) =>
    <String, dynamic>{
      'id': instance.id,
      'enabled': instance.enabled,
      'offset': const Vec2Converter().toJson(instance.offset),
      'blurSigma': instance.blurSigma,
      'color': instance.color,
    };
