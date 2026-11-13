// Path: lib/src/runtime/model/node_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/foundation/math/affine2d.dart';
import 'package:canvas_core/src/foundation/ids.dart'
    show CanvasAssetId, ElementId;
import 'package:canvas_core/src/foundation/paint/canvas_fill.dart';
import 'package:canvas_core/src/foundation/style/style_types.dart'
    show FillRule;
import 'package:canvas_core/src/path/path_source.dart';
import 'package:canvas_core/src/serialization/converters.dart';
import 'package:canvas_core/src/serialization/path_converters.dart';
import 'package:canvas_core/src/runtime/model/canvas_appearance.dart';

part 'node_model.freezed.dart';
part 'node_model.g.dart';

enum ImageFit { contain, cover, fill }

/// Ordinary scene layer with hierarchical affine placement.
///
/// Every node participates in evaluation according to its type, geometry,
/// appearance, transform, and hierarchy. Host authoring settings and editor
/// session state belong to their owning applications.
///
/// Notes:
/// - All nodes (including groups) have a complete local-to-parent Affine2D.
/// - Group nodes structurally own children (no groupId).
/// - IDs are intended to be globally unique within the document.
/// - Optional user-facing display names live in [name].
/// - Sibling order is paint/stack order:
///   earlier siblings paint behind later siblings.
@Freezed(unionKey: 'type')
sealed class Node with _$Node {
  const Node._();

  const factory Node.text({
    required ElementId id,
    @JsonKey(includeIfNull: false) String? name,
    @JsonKey(includeIfNull: false)
    @Affine2DConverter()
    @Default(Affine2D.identity())
    Affine2D xf,
    required String text,
    required String fontFamily,
    required FontWeightNum fontWeight,
    required double fontSize,

    /// Additional spacing between characters in logical canvas units.
    ///
    /// The original text must remain unchanged. Platform text implementations
    /// must apply this value through their native text-layout API.
    @JsonKey(toJson: _letterSpacingToJson, includeIfNull: false)
    @Default(0.0)
    double letterSpacing,

    /// Source-derived visual appearance.
    ///
    /// Layout and interaction geometry remain source-derived and do not expand
    /// for source underlays.
    @Default(CanvasAppearance()) CanvasAppearance appearance,
  }) = TextNode;

  const factory Node.image({
    required ElementId id,
    @JsonKey(includeIfNull: false) String? name,
    @JsonKey(includeIfNull: false)
    @Affine2DConverter()
    @Default(Affine2D.identity())
    Affine2D xf,

    /// Null represents an intentionally unfilled image frame.
    @JsonKey(includeIfNull: false) CanvasAssetId? assetId,

    /// Editable destination-frame dimensions in document units.
    @Size2DConverter() required Size2D size,
    @JsonKey(toJson: _imageFitToJson, includeIfNull: false)
    @Default(ImageFit.contain)
    ImageFit fit,
    @JsonKey(
      fromJson: Vec2.fromJson,
      toJson: _imageAlignToJson,
      includeIfNull: false,
    )
    @Default(Vec2(0.5, 0.5))
    Vec2 align,
  }) = ImageNode;

  const factory Node.path({
    required ElementId id,
    @JsonKey(includeIfNull: false) String? name,
    @JsonKey(includeIfNull: false)
    @Affine2DConverter()
    @Default(Affine2D.identity())
    Affine2D xf,

    /// The sole authored geometry source. Use an explicit empty source for an
    /// intentionally empty path.
    @PathSourceConverter() required PathSource geometry,
    @JsonKey(toJson: _fillRuleToJson, includeIfNull: false)
    @Default(FillRule.nonZero)
    FillRule fillRule,
    @Default(CanvasAppearance(foreground: CanvasFill.none()))
    CanvasAppearance appearance,
  }) = PathNode;

  const factory Node.icon({
    required ElementId id,
    @JsonKey(includeIfNull: false) String? name,
    @JsonKey(includeIfNull: false)
    @Affine2DConverter()
    @Default(Affine2D.identity())
    Affine2D xf,
    required String iconRef,
    @JsonKey(toJson: _iconSizeToJson, includeIfNull: false)
    @Default(96.0)
    double sizePx,
    @Default(CanvasAppearance()) CanvasAppearance appearance,
  }) = IconNode;

  const factory Node.group({
    required ElementId id,
    @JsonKey(includeIfNull: false) String? name,
    @JsonKey(includeIfNull: false)
    @Affine2DConverter()
    @Default(Affine2D.identity())
    Affine2D xf,
    @Default(<Node>[]) List<Node> children,
  }) = GroupNode;

  factory Node.fromJson(Map<String, dynamic> json) => _$NodeFromJson(json);
}

extension NodeFields on Node {
  bool get isGroup => this is GroupNode;

  List<Node> get childrenOrEmpty => switch (this) {
    GroupNode(:final children) => children,
    _ => const <Node>[],
  };
}

String? _fillRuleToJson(FillRule rule) =>
    rule == FillRule.nonZero ? null : rule.name;

double? _letterSpacingToJson(double value) => value == 0 ? null : value;

double? _iconSizeToJson(double value) => value == 96 ? null : value;

String? _imageFitToJson(ImageFit value) =>
    value == ImageFit.contain ? null : value.name;

Map<String, dynamic>? _imageAlignToJson(Vec2 value) =>
    value == const Vec2(0.5, 0.5) ? null : value.toJson();
