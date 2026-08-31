// Path: lib/src/runtime/model/node_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/foundation/ids.dart'
    show CanvasAssetId, ElementId;
import 'package:canvas_core/src/foundation/paint/canvas_fill.dart';
import 'package:canvas_core/src/foundation/style/style_types.dart'
    show FillRule, StrokeCap, StrokeJoin;
import 'package:canvas_core/src/path/path_source.dart';
import 'package:canvas_core/src/serialization/converters.dart';
import 'package:canvas_core/src/serialization/path_converters.dart';

part 'node_model.freezed.dart';
part 'node_model.g.dart';

// Temporary alias retained while downstream package consumers are migrated on
// this draft branch. Remove before the cleanup PR is marked ready.
typedef NodeId = ElementId;

enum OriginKind { center, custom }

@freezed
abstract class Transform2D with _$Transform2D {
  const factory Transform2D({
    @Vec2Converter() @Default(Vec2.zero) Vec2 position,
    @Default(0.0) double rotationRad,
    @Vec2Converter() @Default(Vec2(1, 1)) Vec2 scale,
    @Default(OriginKind.center) OriginKind origin,
    @NullableVec2Converter() Vec2? customPivotPx,
  }) = _Transform2D;

  factory Transform2D.fromJson(Map<String, dynamic> json) =>
      _$Transform2DFromJson(json);
}

@freezed
abstract class TextData with _$TextData {
  const TextData._();

  @Assert('fill is! CanvasFillNone', 'Text fill cannot be none')
  const factory TextData({
    required String text,
    required String fontFamily,
    required FontWeightNum fontWeight,
    required double fontSize,
    @Default(0.0) double letterSpacing,
    @CanvasFillConverter()
    @Default(CanvasFill.solid(0xFF111111))
    CanvasFill fill,
    @Default(0) double shadowOffset,
  }) = _TextData;

  factory TextData.fromJson(Map<String, dynamic> json) =>
      _$TextDataFromJson(json);
}

enum ImageFit { contain, cover, fill }

@freezed
abstract class ImageData with _$ImageData {
  const factory ImageData({
    CanvasAssetId? assetId,
    @Size2DConverter() required Size2D size,
    @Default(ImageFit.contain) ImageFit fit,
    @Vec2Converter() @Default(Vec2(0.5, 0.5)) Vec2 align,
  }) = _ImageData;

  factory ImageData.fromJson(Map<String, dynamic> json) =>
      _$ImageDataFromJson(json);
}

@freezed
abstract class PathData with _$PathData {
  const factory PathData({
    @Vec2ListNullableConverter() @Default(<Vec2?>[]) List<Vec2?> points,
    @PathSourceConverter() PathSource? source,
    @CanvasFillConverter() @Default(CanvasFillNone()) CanvasFill fill,
    @Default(FillRule.nonZero) FillRule fillRule,
    @Default(0x00000000) Color32 strokeColor,
    @Default(4.0) double strokeWidth,
    @Default(StrokeCap.butt) StrokeCap strokeCap,
    @Default(StrokeJoin.miter) StrokeJoin strokeJoin,
    @Default(4.0) double miterLimit,
    @Default(<double>[]) List<double> dash,
  }) = _PathData;

  factory PathData.fromJson(Map<String, dynamic> json) =>
      _$PathDataFromJson(json);
}

@freezed
abstract class CanvasIconData with _$CanvasIconData {
  const CanvasIconData._();

  @Assert('fill is! CanvasFillNone', 'Icon fill cannot be none')
  const factory CanvasIconData({
    required String iconRef,
    @Default(96.0) double sizePx,
    @CanvasFillConverter()
    @Default(CanvasFill.solid(0xFF111111))
    CanvasFill fill,
    @Default(0) double shadowOffset,
  }) = _CanvasIconData;

  factory CanvasIconData.fromJson(Map<String, dynamic> json) =>
      _$CanvasIconDataFromJson(json);
}

@freezed
abstract class GroupBehaviorRef with _$GroupBehaviorRef {
  const factory GroupBehaviorRef({
    required String type,
    required int version,
    required Map<String, dynamic> data,
  }) = _GroupBehaviorRef;

  factory GroupBehaviorRef.fromJson(Map<String, dynamic> json) =>
      _$GroupBehaviorRefFromJson(json);
}

@Freezed(unionKey: 'runtimeType')
sealed class Node with _$Node {
  const Node._();

  const factory Node.text({
    required ElementId id,
    String? name,
    @Default(false) bool hidden,
    @Default(false) bool locked,
    @Default(Transform2D()) Transform2D xf,
    required TextData data,
    String? role,
  }) = TextNode;

  const factory Node.image({
    required ElementId id,
    String? name,
    @Default(false) bool hidden,
    @Default(false) bool locked,
    @Default(Transform2D()) Transform2D xf,
    required ImageData data,
    String? role,
  }) = ImageNode;

  const factory Node.path({
    required ElementId id,
    String? name,
    @Default(false) bool hidden,
    @Default(false) bool locked,
    @Default(Transform2D()) Transform2D xf,
    required PathData data,
    String? role,
  }) = PathNode;

  const factory Node.icon({
    required ElementId id,
    String? name,
    @Default(false) bool hidden,
    @Default(false) bool locked,
    @Default(Transform2D()) Transform2D xf,
    required CanvasIconData data,
    String? role,
  }) = IconNode;

  const factory Node.group({
    required ElementId id,
    String? name,
    @Default(false) bool hidden,
    @Default(false) bool locked,
    @Default(Transform2D()) Transform2D xf,
    GroupBehaviorRef? behavior,
    @Default(<Node>[]) List<Node> children,
  }) = GroupNode;

  factory Node.fromJson(Map<String, dynamic> json) => _$NodeFromJson(json);
}

extension NodeFields on Node {
  ElementId get id => switch (this) {
    TextNode(:final id) => id,
    ImageNode(:final id) => id,
    PathNode(:final id) => id,
    IconNode(:final id) => id,
    GroupNode(:final id) => id,
  };

  String? get name => switch (this) {
    TextNode(:final name) => name,
    ImageNode(:final name) => name,
    PathNode(:final name) => name,
    IconNode(:final name) => name,
    GroupNode(:final name) => name,
  };

  bool get hidden => switch (this) {
    TextNode(:final hidden) => hidden,
    ImageNode(:final hidden) => hidden,
    PathNode(:final hidden) => hidden,
    IconNode(:final hidden) => hidden,
    GroupNode(:final hidden) => hidden,
  };

  bool get locked => switch (this) {
    TextNode(:final locked) => locked,
    ImageNode(:final locked) => locked,
    PathNode(:final locked) => locked,
    IconNode(:final locked) => locked,
    GroupNode(:final locked) => locked,
  };

  Transform2D get xf => switch (this) {
    TextNode(:final xf) => xf,
    ImageNode(:final xf) => xf,
    PathNode(:final xf) => xf,
    IconNode(:final xf) => xf,
    GroupNode(:final xf) => xf,
  };

  String? get role => switch (this) {
    TextNode(:final role) => role,
    ImageNode(:final role) => role,
    PathNode(:final role) => role,
    IconNode(:final role) => role,
    GroupNode() => null,
  };

  bool get isGroup => this is GroupNode;

  List<Node> get childrenOrEmpty => switch (this) {
    GroupNode(:final children) => children,
    _ => const <Node>[],
  };
}
