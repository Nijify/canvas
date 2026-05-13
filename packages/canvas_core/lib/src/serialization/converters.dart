// Path: oss_packages/canvas_core/lib/src/serialization/converters.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/serialization/json_vec2.dart';
import 'package:canvas_core/src/foundation/paint/canvas_fill.dart';

/// ---- Vec2 ----
class Vec2Converter implements JsonConverter<Vec2, Map<String, dynamic>> {
  const Vec2Converter();
  @override
  Vec2 fromJson(Map<String, dynamic> json) => Vec2.fromJson(json);
  @override
  Map<String, dynamic> toJson(Vec2 object) => object.toJson();
}

class NullableVec2Converter
    implements JsonConverter<Vec2?, Map<String, dynamic>?> {
  const NullableVec2Converter();
  @override
  Vec2? fromJson(Map<String, dynamic>? json) =>
      json == null ? null : Vec2.fromJson(json);
  @override
  Map<String, dynamic>? toJson(Vec2? object) => object?.toJson();
}

/// ---- Vec2 list (nullable items) ----
class Vec2ListNullableConverter extends JsonConverter<List<Vec2?>, Object?> {
  const Vec2ListNullableConverter();
  @override
  List<Vec2?> fromJson(Object? json) => vec2ListNullableFromJson(json);
  @override
  Object? toJson(List<Vec2?> value) => vec2ListNullableToJson(value);
}

/// ---- Size2D ----
class Size2DConverter implements JsonConverter<Size2D, Map<String, dynamic>> {
  const Size2DConverter();
  @override
  Size2D fromJson(Map<String, dynamic> json) => Size2D.fromJson(json);
  @override
  Map<String, dynamic> toJson(Size2D object) => object.toJson();
}

class NullableSize2DConverter
    implements JsonConverter<Size2D?, Map<String, dynamic>?> {
  const NullableSize2DConverter();
  @override
  Size2D? fromJson(Map<String, dynamic>? json) =>
      json == null ? null : Size2D.fromJson(json);
  @override
  Map<String, dynamic>? toJson(Size2D? object) => object?.toJson();
}

/// ---- LinearGradientSpec ----
class LinearGradientSpecConverter
    implements JsonConverter<LinearGradientSpec, Map<String, dynamic>> {
  const LinearGradientSpecConverter();

  @override
  LinearGradientSpec fromJson(Map<String, dynamic> json) =>
      LinearGradientSpec.fromJson(json);

  @override
  Map<String, dynamic> toJson(LinearGradientSpec object) => object.toJson();
}

class CanvasFillConverter
    implements JsonConverter<CanvasFill, Map<String, dynamic>> {
  const CanvasFillConverter();

  @override
  CanvasFill fromJson(Map<String, dynamic> json) =>
      CanvasFill.fromJson(json.cast<String, Object?>());

  @override
  Map<String, dynamic> toJson(CanvasFill object) =>
      object.toJson().cast<String, dynamic>();
}
