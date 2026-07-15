// Path: lib/src/foundation/fields/canvas_field_key.dart

import 'package:json_annotation/json_annotation.dart';

/// Stable identity for a runtime-editable canvas field.
///
/// This is intentionally a value object rather than an enum:
/// - canvas_core owns built-in runtime scene fields;
/// - packages can define their own field keys without changing canvas_core;
/// - field keys can be shared across editing, binding, serialization, and other
///   higher-level systems without coupling those systems to each other.
final class CanvasFieldKey {
  const CanvasFieldKey(this.value);

  /// Stable serialized field id.
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CanvasFieldKey && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Built-in field keys for properties that exist in the base canvas_core
/// runtime scene model.
///
/// Packages should define their own CanvasFieldKey constants for fields that
/// are not part of the base runtime scene model.
abstract final class CanvasFields {
  // Text
  static const textContent = CanvasFieldKey('text.content');
  static const textFill = CanvasFieldKey('text.fill');
  static const textFontFamily = CanvasFieldKey('text.fontFamily');
  static const textFontSize = CanvasFieldKey('text.fontSize');
  static const textFontWeight = CanvasFieldKey('text.fontWeight');
  static const textLetterSpacing = CanvasFieldKey('text.letterSpacing');
  static const textShadowOffset = CanvasFieldKey('text.shadowOffset');

  // Icon
  static const iconRef = CanvasFieldKey('icon.ref');
  static const iconFill = CanvasFieldKey('icon.fill');
  static const iconSizePx = CanvasFieldKey('icon.sizePx');
  static const iconShadowOffset = CanvasFieldKey('icon.shadowOffset');

  // Image
  static const imageSource = CanvasFieldKey('image.source');
  static const imageWidthPx = CanvasFieldKey('image.widthPx');
  static const imageHeightPx = CanvasFieldKey('image.heightPx');

  // Path
  static const pathFill = CanvasFieldKey('path.fill');

  // Scene background
  static const sceneBackgroundFill = CanvasFieldKey('scene.backgroundFill');
  static const sceneBackgroundOpacity = CanvasFieldKey(
    'scene.backgroundOpacity',
  );
}

/// Serializes CanvasFieldKey as its stable string value.
///
/// This lets generated JSON models store field keys as:
///
/// ```json
/// { "field": "text.content" }
/// ```
///
/// instead of object-shaped JSON.
class CanvasFieldKeyConverter implements JsonConverter<CanvasFieldKey, String> {
  const CanvasFieldKeyConverter();

  @override
  CanvasFieldKey fromJson(String json) => CanvasFieldKey(json);

  @override
  String toJson(CanvasFieldKey object) => object.value;
}
