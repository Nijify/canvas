// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_appearance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
                (e) => const _CanvasSourceUnderlayJsonConverter().fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const <CanvasSourceUnderlay>[],
    );

Map<String, dynamic> _$CanvasAppearanceToJson(_CanvasAppearance instance) =>
    <String, dynamic>{
      'foreground': const CanvasFillConverter().toJson(instance.foreground),
      'underlays': instance.underlays
          .map(const _CanvasSourceUnderlayJsonConverter().toJson)
          .toList(),
    };
