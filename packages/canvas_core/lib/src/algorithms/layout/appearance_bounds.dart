import 'dart:math' as math;

import 'package:canvas_core/src/foundation/geometry/geometry.dart';
import 'package:canvas_core/src/foundation/geometry/geometry_ext.dart';
import 'package:canvas_core/src/foundation/paint/canvas_fill.dart';
import 'package:canvas_core/src/foundation/style/style_types.dart';
import 'package:canvas_core/src/runtime/model/canvas_appearance.dart';
import 'package:canvas_core/src/runtime/model/canvas_stroke.dart';

bool _colorContributesToPaint(int color) =>
    color >= 0 && color <= 0xFFFFFFFF && ((color >> 24) & 0xFF) != 0;

/// Whether a foreground has any visible color. Geometry and node visibility
/// are evaluated separately; source underlays do not depend on this result.
bool fillContributesToPaint(CanvasFill fill) => switch (fill) {
  CanvasFillNone() => false,
  CanvasFillSolid(:final color) => _colorContributesToPaint(color),
  CanvasFillGradient(:final grad) => grad.stops.any(
    (stop) => _colorContributesToPaint(stop.color),
  ),
};

/// Whether the configured stroke can paint pixels. Invalid colors and widths
/// are skipped defensively; validation still reports them on invisible strokes.
bool strokeContributesToPaint(CanvasStroke? stroke) =>
    stroke != null &&
    _colorContributesToPaint(stroke.color) &&
    stroke.width.isFinite &&
    stroke.width > 0;

/// Conservative local paint bounds for an ordinary path. Pass null for empty
/// geometry or contours containing only moves. Zero-width/height bounds remain
/// valid sources, including stroked horizontal or vertical lines.
///
/// Square caps may extend diagonally by sqrt(2) times the stroke radius;
/// miter joins may extend by the miter limit times that radius. This estimate
/// can include unused space, and does not include raster antialiasing padding.
/// Dash metadata currently paints as a solid stroke. Paths have no underlays.
Rect2D? estimatePathPaintBounds({
  required Rect2D? sourceBounds,
  required CanvasAppearance appearance,
}) {
  if (sourceBounds == null) return null;

  final stroke = appearance.stroke;
  if (stroke != null && strokeContributesToPaint(stroke)) {
    var multiplier = stroke.cap == StrokeCap.square ? math.sqrt2 : 1.0;
    if (stroke.join == StrokeJoin.miter && stroke.miterLimit.isFinite) {
      multiplier = math.max(multiplier, stroke.miterLimit);
    }
    return sourceBounds.inflate(stroke.width / 2 * multiplier);
  }

  return fillContributesToPaint(appearance.foreground) ? sourceBounds : null;
}

/// Practical Gaussian-tail estimate, not a hard pixel-enclosure guarantee.
/// Raster padding remains a separate export policy.
const double shadowBlurExtentInSigmas = 4.0;

/// Invalid numeric/color values are skipped defensively by bounds/rendering.
/// The document validator still reports invalid authored data, including for
/// disabled effects.
bool shadowContributesToPaint(ShadowEffect shadow) =>
    shadow.enabled &&
    _colorContributesToPaint(shadow.color) &&
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
