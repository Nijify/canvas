// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scene_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CanvasSceneDocument _$CanvasSceneDocumentFromJson(Map<String, dynamic> json) =>
    _CanvasSceneDocument(
      artboardSize: json['artboardSize'] == null
          ? const Size2D(740, 360)
          : const Size2DConverter().fromJson(
              json['artboardSize'] as Map<String, dynamic>,
            ),
      bgGradient: json['bgGradient'] == null
          ? LinearGradientSpec.transparent
          : const LinearGradientSpecConverter().fromJson(
              json['bgGradient'] as Map<String, dynamic>,
            ),
      bgOpacity: (json['bgOpacity'] as num?)?.toDouble() ?? 0.0,
      children:
          (json['children'] as List<dynamic>?)
              ?.map((e) => Node.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Node>[],
    );

Map<String, dynamic> _$CanvasSceneDocumentToJson(
  _CanvasSceneDocument instance,
) => <String, dynamic>{
  'artboardSize': const Size2DConverter().toJson(instance.artboardSize),
  'bgGradient': const LinearGradientSpecConverter().toJson(instance.bgGradient),
  'bgOpacity': instance.bgOpacity,
  'children': instance.children.map((e) => e.toJson()).toList(),
};
