import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/serialization/converters.dart';

part 'shadow_effect.freezed.dart';
part 'shadow_effect.g.dart';

/// A shadow derived from the original source silhouette.
///
/// Shadow coverage, color, and opacity are independent of the authored
/// foreground fill's color and alpha. Text and icon nodes still require a
/// non-`none` foreground fill in the current document model.
///
/// Lists are painted back-to-front, then the foreground is painted.
/// Offsets and Gaussian sigma are in object-local document units.
/// IDs are stable and unique within the owning node's shadow list.
@freezed
abstract class ShadowEffect with _$ShadowEffect {
  const factory ShadowEffect({
    required String id,
    @Default(true) bool enabled,
    @Vec2Converter() required Vec2 offset,
    @Default(0.0) double blurSigma,
    required Color32 color,
  }) = _ShadowEffect;

  factory ShadowEffect.fromJson(Map<String, dynamic> json) =>
      _$ShadowEffectFromJson(json);
}
