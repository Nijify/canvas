// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scene_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CanvasSceneDocument _$CanvasSceneDocumentFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['backgroundFill', 'backgroundOpacity'],
    disallowNullValues: const ['backgroundFill', 'backgroundOpacity'],
  );
  return _CanvasSceneDocument(
    artboardSize: json['artboardSize'] == null
        ? const Size2D(740, 360)
        : const Size2DConverter().fromJson(
            json['artboardSize'] as Map<String, dynamic>,
          ),
    backgroundFill: const CanvasFillConverter().fromJson(
      json['backgroundFill'] as Map<String, dynamic>,
    ),
    backgroundOpacity: (json['backgroundOpacity'] as num).toDouble(),
    children:
        (json['children'] as List<dynamic>?)
            ?.map((e) => Node.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <Node>[],
  );
}

Map<String, dynamic> _$CanvasSceneDocumentToJson(
  _CanvasSceneDocument instance,
) => <String, dynamic>{
  'artboardSize': const Size2DConverter().toJson(instance.artboardSize),
  'backgroundFill': const CanvasFillConverter().toJson(instance.backgroundFill),
  'backgroundOpacity': instance.backgroundOpacity,
  'children': instance.children.map((e) => e.toJson()).toList(),
};
