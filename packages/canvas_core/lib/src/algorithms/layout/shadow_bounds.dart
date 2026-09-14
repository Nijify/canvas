import 'package:canvas_core/src/foundation/geometry/geometry.dart';
import 'package:canvas_core/src/foundation/geometry/geometry_ext.dart';
import 'package:canvas_core/src/runtime/model/shadow_effect.dart';

/// Practical Gaussian-tail estimate, not a hard pixel-enclosure guarantee.
/// Raster padding remains a separate export policy.
const double shadowBlurExtentInSigmas = 4.0;

/// Invalid numeric/color values are skipped defensively by bounds/rendering.
/// The document validator still reports them, including on disabled shadows.
bool shadowContributesToPaint(ShadowEffect shadow) =>
    shadow.enabled &&
    shadow.color >= 0 &&
    shadow.color <= 0xFFFFFFFF &&
    ((shadow.color >> 24) & 0xFF) != 0 &&
    shadow.offset.x.isFinite &&
    shadow.offset.y.isFinite &&
    shadow.blurSigma.isFinite &&
    shadow.blurSigma >= 0;

/// Every shadow expands the ORIGINAL estimate, never a preceding shadow.
/// Does not change layout, pivots, or interaction geometry.
Rect2D? estimateShadowPaintBounds(
  Rect2D? basePaint,
  Iterable<ShadowEffect> shadows,
) {
  if (basePaint == null) return null;
  var result = basePaint;
  for (final shadow in shadows) {
    if (!shadowContributesToPaint(shadow)) continue;
    final extent = basePaint
        .inflate(shadowBlurExtentInSigmas * shadow.blurSigma)
        .translate(shadow.offset);
    result = Rect2DX.union(result, extent);
  }
  return result;
}
