import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/foundation/paint/canvas_fill.dart';
import 'package:canvas_core/src/serialization/converters.dart';

part 'canvas_appearance.freezed.dart';
part 'canvas_appearance.g.dart';

/// Ordered paint that derives independently from the original source
/// silhouette and is painted before the authored foreground.
///
/// Index 0 is backmost.
///
/// Every underlay derives from the original source silhouette. Underlays never
/// consume the output of a preceding underlay.
@Freezed(unionKey: 'type')
sealed class CanvasSourceUnderlay with _$CanvasSourceUnderlay {
  const factory CanvasSourceUnderlay.shadow({
    required String id,
    @Default(true) bool enabled,
    @Vec2Converter() required Vec2 offset,
    @Default(0.0) double blurSigma,
    required Color32 color,
  }) = ShadowEffect;

  factory CanvasSourceUnderlay.fromJson(Map<String, dynamic> json) =>
      _$CanvasSourceUnderlayFromJson(json);
}

/// Appearance shared by text and icon sources.
///
/// [foreground] controls whether/how the authored source itself is painted.
/// `CanvasFill.none()` is valid: the source silhouette still exists and may be
/// consumed by [underlays].
///
/// Underlays are painted back-to-front before the foreground.
@freezed
abstract class CanvasAppearance with _$CanvasAppearance {
  const factory CanvasAppearance({
    @CanvasFillConverter()
    @Default(CanvasFill.solid(0xFF111111))
    CanvasFill foreground,
    @Default(<CanvasSourceUnderlay>[]) List<CanvasSourceUnderlay> underlays,
  }) = _CanvasAppearance;

  factory CanvasAppearance.fromJson(Map<String, dynamic> json) =>
      _$CanvasAppearanceFromJson(json);
}
