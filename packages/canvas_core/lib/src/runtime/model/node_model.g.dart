// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextNode _$TextNodeFromJson(Map<String, dynamic> json) => TextNode(
  id: json['id'] as String,
  name: json['name'] as String?,
  xf: json['xf'] == null
      ? const Affine2D.identity()
      : const Affine2DConverter().fromJson(json['xf']),
  text: json['text'] as String,
  fontFamily: json['fontFamily'] as String,
  fontWeight: (json['fontWeight'] as num).toInt(),
  fontSize: (json['fontSize'] as num).toDouble(),
  letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
  appearance: json['appearance'] == null
      ? const CanvasAppearance()
      : CanvasAppearance.fromJson(json['appearance'] as Map<String, dynamic>),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$TextNodeToJson(TextNode instance) => <String, dynamic>{
  'id': instance.id,
  'name': ?instance.name,
  'xf': ?const Affine2DConverter().toJson(instance.xf),
  'text': instance.text,
  'fontFamily': instance.fontFamily,
  'fontWeight': instance.fontWeight,
  'fontSize': instance.fontSize,
  'letterSpacing': ?_letterSpacingToJson(instance.letterSpacing),
  'appearance': instance.appearance.toJson(),
  'type': instance.$type,
};

ImageNode _$ImageNodeFromJson(Map<String, dynamic> json) => ImageNode(
  id: json['id'] as String,
  name: json['name'] as String?,
  xf: json['xf'] == null
      ? const Affine2D.identity()
      : const Affine2DConverter().fromJson(json['xf']),
  assetId: json['assetId'] as String?,
  size: const Size2DConverter().fromJson(json['size'] as Map<String, dynamic>),
  fit: $enumDecodeNullable(_$ImageFitEnumMap, json['fit']) ?? ImageFit.contain,
  align: json['align'] == null
      ? const Vec2(0.5, 0.5)
      : Vec2.fromJson(json['align'] as Map<String, dynamic>),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$ImageNodeToJson(ImageNode instance) => <String, dynamic>{
  'id': instance.id,
  'name': ?instance.name,
  'xf': ?const Affine2DConverter().toJson(instance.xf),
  'assetId': ?instance.assetId,
  'size': const Size2DConverter().toJson(instance.size),
  'fit': ?_imageFitToJson(instance.fit),
  'align': ?_imageAlignToJson(instance.align),
  'type': instance.$type,
};

const _$ImageFitEnumMap = {
  ImageFit.contain: 'contain',
  ImageFit.cover: 'cover',
  ImageFit.fill: 'fill',
};

PathNode _$PathNodeFromJson(Map<String, dynamic> json) => PathNode(
  id: json['id'] as String,
  name: json['name'] as String?,
  xf: json['xf'] == null
      ? const Affine2D.identity()
      : const Affine2DConverter().fromJson(json['xf']),
  geometry: const PathSourceConverter().fromJson(json['geometry']),
  fillRule:
      $enumDecodeNullable(_$FillRuleEnumMap, json['fillRule']) ??
      FillRule.nonZero,
  appearance: json['appearance'] == null
      ? const CanvasAppearance(foreground: CanvasFill.none())
      : CanvasAppearance.fromJson(json['appearance'] as Map<String, dynamic>),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$PathNodeToJson(PathNode instance) => <String, dynamic>{
  'id': instance.id,
  'name': ?instance.name,
  'xf': ?const Affine2DConverter().toJson(instance.xf),
  'geometry': const PathSourceConverter().toJson(instance.geometry),
  'fillRule': ?_fillRuleToJson(instance.fillRule),
  'appearance': instance.appearance.toJson(),
  'type': instance.$type,
};

const _$FillRuleEnumMap = {
  FillRule.nonZero: 'nonZero',
  FillRule.evenOdd: 'evenOdd',
};

IconNode _$IconNodeFromJson(Map<String, dynamic> json) => IconNode(
  id: json['id'] as String,
  name: json['name'] as String?,
  xf: json['xf'] == null
      ? const Affine2D.identity()
      : const Affine2DConverter().fromJson(json['xf']),
  iconRef: json['iconRef'] as String,
  sizePx: (json['sizePx'] as num?)?.toDouble() ?? 96.0,
  appearance: json['appearance'] == null
      ? const CanvasAppearance()
      : CanvasAppearance.fromJson(json['appearance'] as Map<String, dynamic>),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$IconNodeToJson(IconNode instance) => <String, dynamic>{
  'id': instance.id,
  'name': ?instance.name,
  'xf': ?const Affine2DConverter().toJson(instance.xf),
  'iconRef': instance.iconRef,
  'sizePx': ?_iconSizeToJson(instance.sizePx),
  'appearance': instance.appearance.toJson(),
  'type': instance.$type,
};

GroupNode _$GroupNodeFromJson(Map<String, dynamic> json) => GroupNode(
  id: json['id'] as String,
  name: json['name'] as String?,
  xf: json['xf'] == null
      ? const Affine2D.identity()
      : const Affine2DConverter().fromJson(json['xf']),
  children:
      (json['children'] as List<dynamic>?)
          ?.map((e) => Node.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Node>[],
  $type: json['type'] as String?,
);

Map<String, dynamic> _$GroupNodeToJson(GroupNode instance) => <String, dynamic>{
  'id': instance.id,
  'name': ?instance.name,
  'xf': ?const Affine2DConverter().toJson(instance.xf),
  'children': instance.children.map((e) => e.toJson()).toList(),
  'type': instance.$type,
};
