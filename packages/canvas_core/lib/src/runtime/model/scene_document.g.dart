// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scene_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CanvasImageAsset _$CanvasImageAssetFromJson(Map<String, dynamic> json) =>
    _CanvasImageAsset(
      sourceRef: json['sourceRef'] as String,
      intrinsicSize: const NullableSize2DConverter().fromJson(
        json['intrinsicSize'] as Map<String, dynamic>?,
      ),
    );

Map<String, dynamic> _$CanvasImageAssetToJson(_CanvasImageAsset instance) =>
    <String, dynamic>{
      'sourceRef': instance.sourceRef,
      'intrinsicSize': const NullableSize2DConverter().toJson(
        instance.intrinsicSize,
      ),
    };

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
    assets:
        (json['assets'] as Map<String, dynamic>?)?.map(
          (k, e) =>
              MapEntry(k, CanvasImageAsset.fromJson(e as Map<String, dynamic>)),
        ) ??
        const <CanvasAssetId, CanvasImageAsset>{},
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
  'assets': instance.assets.map((k, e) => MapEntry(k, e.toJson())),
  'children': instance.children.map((e) => e.toJson()).toList(),
};
