// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Transform2D _$Transform2DFromJson(Map<String, dynamic> json) => _Transform2D(
  position: json['position'] == null
      ? Vec2.zero
      : const Vec2Converter().fromJson(
          json['position'] as Map<String, dynamic>,
        ),
  rotationRad: (json['rotationRad'] as num?)?.toDouble() ?? 0.0,
  scale: json['scale'] == null
      ? const Vec2(1, 1)
      : const Vec2Converter().fromJson(json['scale'] as Map<String, dynamic>),
  origin:
      $enumDecodeNullable(_$OriginKindEnumMap, json['origin']) ??
      OriginKind.center,
  customPivotPx: const NullableVec2Converter().fromJson(
    json['customPivotPx'] as Map<String, dynamic>?,
  ),
);

Map<String, dynamic> _$Transform2DToJson(
  _Transform2D instance,
) => <String, dynamic>{
  'position': const Vec2Converter().toJson(instance.position),
  'rotationRad': instance.rotationRad,
  'scale': const Vec2Converter().toJson(instance.scale),
  'origin': _$OriginKindEnumMap[instance.origin]!,
  'customPivotPx': const NullableVec2Converter().toJson(instance.customPivotPx),
};

const _$OriginKindEnumMap = {
  OriginKind.center: 'center',
  OriginKind.custom: 'custom',
};

_TextData _$TextDataFromJson(Map<String, dynamic> json) => _TextData(
  text: json['text'] as String,
  fontFamily: json['fontFamily'] as String,
  fontWeight: (json['fontWeight'] as num).toInt(),
  fontSize: (json['fontSize'] as num).toDouble(),
  letterSpacing: (json['letterSpacing'] as num?)?.toInt() ?? 0,
  fill: json['fill'] == null
      ? const CanvasFill.solid(0xFF111111)
      : const CanvasFillConverter().fromJson(
          json['fill'] as Map<String, dynamic>,
        ),
  shadowOffset: (json['shadowOffset'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$TextDataToJson(_TextData instance) => <String, dynamic>{
  'text': instance.text,
  'fontFamily': instance.fontFamily,
  'fontWeight': instance.fontWeight,
  'fontSize': instance.fontSize,
  'letterSpacing': instance.letterSpacing,
  'fill': const CanvasFillConverter().toJson(instance.fill),
  'shadowOffset': instance.shadowOffset,
};

_ImageData _$ImageDataFromJson(Map<String, dynamic> json) => _ImageData(
  size: const NullableSize2DConverter().fromJson(
    json['size'] as Map<String, dynamic>?,
  ),
  sourcePath: json['sourcePath'] as String?,
  fit: $enumDecodeNullable(_$ImageFitEnumMap, json['fit']) ?? ImageFit.contain,
  align: json['align'] == null
      ? const Vec2(0.5, 0.5)
      : const Vec2Converter().fromJson(json['align'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ImageDataToJson(_ImageData instance) =>
    <String, dynamic>{
      'size': const NullableSize2DConverter().toJson(instance.size),
      'sourcePath': instance.sourcePath,
      'fit': _$ImageFitEnumMap[instance.fit]!,
      'align': const Vec2Converter().toJson(instance.align),
    };

const _$ImageFitEnumMap = {
  ImageFit.contain: 'contain',
  ImageFit.cover: 'cover',
  ImageFit.fill: 'fill',
};

_PathData _$PathDataFromJson(Map<String, dynamic> json) => _PathData(
  points: json['points'] == null
      ? const <Vec2?>[]
      : const Vec2ListNullableConverter().fromJson(json['points']),
  source: const PathSourceConverter().fromJson(json['source']),
  fill: json['fill'] == null
      ? const CanvasFillNone()
      : const CanvasFillConverter().fromJson(
          json['fill'] as Map<String, dynamic>,
        ),
  fillRule:
      $enumDecodeNullable(_$FillRuleEnumMap, json['fillRule']) ??
      FillRule.nonZero,
  strokeColor: (json['strokeColor'] as num?)?.toInt() ?? 0x00000000,
  strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 4.0,
  strokeCap:
      $enumDecodeNullable(_$StrokeCapEnumMap, json['strokeCap']) ??
      StrokeCap.butt,
  strokeJoin:
      $enumDecodeNullable(_$StrokeJoinEnumMap, json['strokeJoin']) ??
      StrokeJoin.miter,
  miterLimit: (json['miterLimit'] as num?)?.toDouble() ?? 4.0,
  dash:
      (json['dash'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ??
      const <double>[],
);

Map<String, dynamic> _$PathDataToJson(_PathData instance) => <String, dynamic>{
  'points': const Vec2ListNullableConverter().toJson(instance.points),
  'source': const PathSourceConverter().toJson(instance.source),
  'fill': const CanvasFillConverter().toJson(instance.fill),
  'fillRule': _$FillRuleEnumMap[instance.fillRule]!,
  'strokeColor': instance.strokeColor,
  'strokeWidth': instance.strokeWidth,
  'strokeCap': _$StrokeCapEnumMap[instance.strokeCap]!,
  'strokeJoin': _$StrokeJoinEnumMap[instance.strokeJoin]!,
  'miterLimit': instance.miterLimit,
  'dash': instance.dash,
};

const _$FillRuleEnumMap = {
  FillRule.nonZero: 'nonZero',
  FillRule.evenOdd: 'evenOdd',
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

_CanvasIconData _$CanvasIconDataFromJson(Map<String, dynamic> json) =>
    _CanvasIconData(
      iconRef: json['iconRef'] as String,
      sizePx: (json['sizePx'] as num?)?.toDouble() ?? 96.0,
      fill: json['fill'] == null
          ? const CanvasFill.solid(0xFF111111)
          : const CanvasFillConverter().fromJson(
              json['fill'] as Map<String, dynamic>,
            ),
      shadowOffset: (json['shadowOffset'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$CanvasIconDataToJson(_CanvasIconData instance) =>
    <String, dynamic>{
      'iconRef': instance.iconRef,
      'sizePx': instance.sizePx,
      'fill': const CanvasFillConverter().toJson(instance.fill),
      'shadowOffset': instance.shadowOffset,
    };

_GroupBehaviorRef _$GroupBehaviorRefFromJson(Map<String, dynamic> json) =>
    _GroupBehaviorRef(
      type: json['type'] as String,
      version: (json['version'] as num?)?.toInt() ?? 1,
      data: json['data'] as Map<String, dynamic>? ?? const <String, dynamic>{},
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
  locked: json['locked'] as bool? ?? false,
  xf: json['xf'] == null
      ? const Transform2D()
      : Transform2D.fromJson(json['xf'] as Map<String, dynamic>),
  data: TextData.fromJson(json['data'] as Map<String, dynamic>),
  role: json['role'] as String?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$TextNodeToJson(TextNode instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'hidden': instance.hidden,
  'locked': instance.locked,
  'xf': instance.xf.toJson(),
  'data': instance.data.toJson(),
  'role': instance.role,
  'runtimeType': instance.$type,
};

ImageNode _$ImageNodeFromJson(Map<String, dynamic> json) => ImageNode(
  id: json['id'] as String,
  name: json['name'] as String?,
  hidden: json['hidden'] as bool? ?? false,
  locked: json['locked'] as bool? ?? false,
  xf: json['xf'] == null
      ? const Transform2D()
      : Transform2D.fromJson(json['xf'] as Map<String, dynamic>),
  data: ImageData.fromJson(json['data'] as Map<String, dynamic>),
  role: json['role'] as String?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$ImageNodeToJson(ImageNode instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'hidden': instance.hidden,
  'locked': instance.locked,
  'xf': instance.xf.toJson(),
  'data': instance.data.toJson(),
  'role': instance.role,
  'runtimeType': instance.$type,
};

PathNode _$PathNodeFromJson(Map<String, dynamic> json) => PathNode(
  id: json['id'] as String,
  name: json['name'] as String?,
  hidden: json['hidden'] as bool? ?? false,
  locked: json['locked'] as bool? ?? false,
  xf: json['xf'] == null
      ? const Transform2D()
      : Transform2D.fromJson(json['xf'] as Map<String, dynamic>),
  data: PathData.fromJson(json['data'] as Map<String, dynamic>),
  role: json['role'] as String?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$PathNodeToJson(PathNode instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'hidden': instance.hidden,
  'locked': instance.locked,
  'xf': instance.xf.toJson(),
  'data': instance.data.toJson(),
  'role': instance.role,
  'runtimeType': instance.$type,
};

IconNode _$IconNodeFromJson(Map<String, dynamic> json) => IconNode(
  id: json['id'] as String,
  name: json['name'] as String?,
  hidden: json['hidden'] as bool? ?? false,
  locked: json['locked'] as bool? ?? false,
  xf: json['xf'] == null
      ? const Transform2D()
      : Transform2D.fromJson(json['xf'] as Map<String, dynamic>),
  data: CanvasIconData.fromJson(json['data'] as Map<String, dynamic>),
  role: json['role'] as String?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$IconNodeToJson(IconNode instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'hidden': instance.hidden,
  'locked': instance.locked,
  'xf': instance.xf.toJson(),
  'data': instance.data.toJson(),
  'role': instance.role,
  'runtimeType': instance.$type,
};

GroupNode _$GroupNodeFromJson(Map<String, dynamic> json) => GroupNode(
  id: json['id'] as String,
  name: json['name'] as String?,
  hidden: json['hidden'] as bool? ?? false,
  locked: json['locked'] as bool? ?? false,
  xf: json['xf'] == null
      ? const Transform2D()
      : Transform2D.fromJson(json['xf'] as Map<String, dynamic>),
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
  'hidden': instance.hidden,
  'locked': instance.locked,
  'xf': instance.xf.toJson(),
  'behavior': instance.behavior?.toJson(),
  'children': instance.children.map((e) => e.toJson()).toList(),
  'runtimeType': instance.$type,
};
