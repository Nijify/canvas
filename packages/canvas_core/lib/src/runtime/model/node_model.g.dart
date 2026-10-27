// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TextData _$TextDataFromJson(Map<String, dynamic> json) => _TextData(
  text: json['text'] as String,
  fontFamily: json['fontFamily'] as String,
  fontWeight: (json['fontWeight'] as num).toInt(),
  fontSize: (json['fontSize'] as num).toDouble(),
  letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
  appearance: json['appearance'] == null
      ? const CanvasAppearance()
      : CanvasAppearance.fromJson(json['appearance'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TextDataToJson(_TextData instance) => <String, dynamic>{
  'text': instance.text,
  'fontFamily': instance.fontFamily,
  'fontWeight': instance.fontWeight,
  'fontSize': instance.fontSize,
  'letterSpacing': instance.letterSpacing,
  'appearance': instance.appearance.toJson(),
};

_ImageData _$ImageDataFromJson(Map<String, dynamic> json) => _ImageData(
  assetId: json['assetId'] as String?,
  size: const Size2DConverter().fromJson(json['size'] as Map<String, dynamic>),
  fit: $enumDecodeNullable(_$ImageFitEnumMap, json['fit']) ?? ImageFit.contain,
  align: json['align'] == null
      ? const Vec2(0.5, 0.5)
      : const Vec2Converter().fromJson(json['align'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ImageDataToJson(_ImageData instance) =>
    <String, dynamic>{
      'assetId': instance.assetId,
      'size': const Size2DConverter().toJson(instance.size),
      'fit': _$ImageFitEnumMap[instance.fit]!,
      'align': const Vec2Converter().toJson(instance.align),
    };

const _$ImageFitEnumMap = {
  ImageFit.contain: 'contain',
  ImageFit.cover: 'cover',
  ImageFit.fill: 'fill',
};

_PathData _$PathDataFromJson(Map<String, dynamic> json) => _PathData(
  source: const PathSourceConverter().fromJson(json['source']),
  fillRule:
      $enumDecodeNullable(_$FillRuleEnumMap, json['fillRule']) ??
      FillRule.nonZero,
  appearance: json['appearance'] == null
      ? const CanvasAppearance(foreground: CanvasFill.none())
      : CanvasAppearance.fromJson(json['appearance'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PathDataToJson(_PathData instance) => <String, dynamic>{
  'source': const PathSourceConverter().toJson(instance.source),
  if (instance.fillRule != FillRule.nonZero)
    'fillRule': _$FillRuleEnumMap[instance.fillRule]!,
  'appearance': instance.appearance.toJson(),
};

const _$FillRuleEnumMap = {
  FillRule.nonZero: 'nonZero',
  FillRule.evenOdd: 'evenOdd',
};

_CanvasIconData _$CanvasIconDataFromJson(Map<String, dynamic> json) =>
    _CanvasIconData(
      iconRef: json['iconRef'] as String,
      sizePx: (json['sizePx'] as num?)?.toDouble() ?? 96.0,
      appearance: json['appearance'] == null
          ? const CanvasAppearance()
          : CanvasAppearance.fromJson(
              json['appearance'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$CanvasIconDataToJson(_CanvasIconData instance) =>
    <String, dynamic>{
      'iconRef': instance.iconRef,
      'sizePx': instance.sizePx,
      'appearance': instance.appearance.toJson(),
    };

_GroupBehaviorRef _$GroupBehaviorRefFromJson(Map<String, dynamic> json) =>
    _GroupBehaviorRef(
      type: json['type'] as String,
      version: (json['version'] as num).toInt(),
      data: json['data'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$GroupBehaviorRefToJson(_GroupBehaviorRef instance) =>
    <String, dynamic>{
      'type': instance.type,
      'version': instance.version,
      'data': instance.data,
    };

TextNode _$TextNodeFromJson(Map<String, dynamic> json) => TextNode(
  id: json['id'] as String,
  name: json['name'] as String?,
  hidden: json['hidden'] as bool? ?? false,
  xf: json.containsKey('xf')
      ? const Affine2DConverter().fromJson(json['xf'])
      : const Affine2D.identity(),
  data: TextData.fromJson(json['data'] as Map<String, dynamic>),
  role: json['role'] as String?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$TextNodeToJson(TextNode instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  if (instance.hidden) 'hidden': true,
  if (!instance.xf.isIdentity) 'xf': instance.xf.toJson(),
  'data': instance.data.toJson(),
  'role': instance.role,
  'runtimeType': instance.$type,
};

ImageNode _$ImageNodeFromJson(Map<String, dynamic> json) => ImageNode(
  id: json['id'] as String,
  name: json['name'] as String?,
  hidden: json['hidden'] as bool? ?? false,
  xf: json.containsKey('xf')
      ? const Affine2DConverter().fromJson(json['xf'])
      : const Affine2D.identity(),
  data: ImageData.fromJson(json['data'] as Map<String, dynamic>),
  role: json['role'] as String?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$ImageNodeToJson(ImageNode instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  if (instance.hidden) 'hidden': true,
  if (!instance.xf.isIdentity) 'xf': instance.xf.toJson(),
  'data': instance.data.toJson(),
  'role': instance.role,
  'runtimeType': instance.$type,
};

PathNode _$PathNodeFromJson(Map<String, dynamic> json) => PathNode(
  id: json['id'] as String,
  name: json['name'] as String?,
  hidden: json['hidden'] as bool? ?? false,
  xf: json.containsKey('xf')
      ? const Affine2DConverter().fromJson(json['xf'])
      : const Affine2D.identity(),
  data: PathData.fromJson(json['data'] as Map<String, dynamic>),
  role: json['role'] as String?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$PathNodeToJson(PathNode instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  if (instance.hidden) 'hidden': true,
  if (!instance.xf.isIdentity) 'xf': instance.xf.toJson(),
  'data': instance.data.toJson(),
  'role': instance.role,
  'runtimeType': instance.$type,
};

IconNode _$IconNodeFromJson(Map<String, dynamic> json) => IconNode(
  id: json['id'] as String,
  name: json['name'] as String?,
  hidden: json['hidden'] as bool? ?? false,
  xf: json.containsKey('xf')
      ? const Affine2DConverter().fromJson(json['xf'])
      : const Affine2D.identity(),
  data: CanvasIconData.fromJson(json['data'] as Map<String, dynamic>),
  role: json['role'] as String?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$IconNodeToJson(IconNode instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  if (instance.hidden) 'hidden': true,
  if (!instance.xf.isIdentity) 'xf': instance.xf.toJson(),
  'data': instance.data.toJson(),
  'role': instance.role,
  'runtimeType': instance.$type,
};

GroupNode _$GroupNodeFromJson(Map<String, dynamic> json) => GroupNode(
  id: json['id'] as String,
  name: json['name'] as String?,
  hidden: json['hidden'] as bool? ?? false,
  xf: json.containsKey('xf')
      ? const Affine2DConverter().fromJson(json['xf'])
      : const Affine2D.identity(),
  behavior: json['behavior'] == null
      ? null
      : GroupBehaviorRef.fromJson(json['behavior'] as Map<String, dynamic>),
  children:
      (json['children'] as List<dynamic>?)
          ?.map((e) => Node.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Node>[],
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$GroupNodeToJson(GroupNode instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  if (instance.hidden) 'hidden': true,
  if (!instance.xf.isIdentity) 'xf': instance.xf.toJson(),
  'behavior': instance.behavior?.toJson(),
  'children': instance.children.map((e) => e.toJson()).toList(),
  'runtimeType': instance.$type,
};
