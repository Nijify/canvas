import 'package:canvas_core/src/foundation/geometry/geometry.dart';
import 'package:canvas_core/src/foundation/geometry/geometry_ext.dart';
import 'package:canvas_core/src/runtime/model/canvas_appearance.dart';

/// Practical Gaussian-tail estimate, not a hard pixel-enclosure guarantee.
/// Raster padding remains a separate export policy.
const double shadowBlurExtentInSigmas = 4.0;

/// Invalid numeric/color values are skipped defensively by bounds/rendering.
/// The document validator still reports invalid authored data, including for
/// disabled effects.
bool shadowContributesToPaint(ShadowEffect shadow) =>
    shadow.enabled &&
    shadow.color >= 0 &&
    shadow.color <= 0xFFFFFFFF &&
    ((shadow.color >> 24) & 0xFF) != 0 &&
    shadow.offset.x.isFinite &&
    shadow.offset.y.isFinite &&
    shadow.blurSigma.isFinite &&
    shadow.blurSigma >= 0;

bool sourceUnderlayContributesToPaint(CanvasSourceUnderlay underlay) {
  return switch (underlay) {
    ShadowEffect() => shadowContributesToPaint(underlay),
  };
}

/// Returns the paint estimate produced by one underlay from the ORIGINAL
/// source bounds.
///
/// Underlays never expand from previously accumulated underlay bounds.
Rect2D? estimateSourceUnderlayPaintBounds(
  Rect2D sourceBounds,
  CanvasSourceUnderlay underlay,
) {
  return switch (underlay) {
    ShadowEffect(:final offset, :final blurSigma) =>
      shadowContributesToPaint(underlay)
          ? sourceBounds
                .inflate(shadowBlurExtentInSigmas * blurSigma)
                .translate(offset)
          : null,
  };
}

/// Estimates visible paint for a text/icon appearance.
///
/// [sourceBounds] describes the original source silhouette estimate.
///
/// The source bounds are included directly only when [foregroundPresent] is
/// true. Underlays always derive independently from [sourceBounds].
///
/// This affects paint/content bounds only. It does not alter source layout,
/// pivots, selection, hit testing, or snapping.
Rect2D? estimateAppearancePaintBounds({
  required Rect2D? sourceBounds,
  required bool foregroundPresent,
  required Iterable<CanvasSourceUnderlay> underlays,
}) {
  if (sourceBounds == null) return null;

  Rect2D? result = foregroundPresent ? sourceBounds : null;

  for (final underlay in underlays) {
    final underlayBounds = estimateSourceUnderlayPaintBounds(
      sourceBounds,
      underlay,
    );

    if (underlayBounds == null) continue;

    result = result == null
        ? underlayBounds
        : Rect2DX.union(result, underlayBounds);
  }

  return result;
}
