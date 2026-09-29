// Path: lib/src/algorithms/viewport/viewport_math.dart

import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;

/// Renderer-neutral contain-fit transform.
///
/// Callers are responsible for choosing the source bounds and applying any
/// higher-level viewport policy such as padding, cropping, or output sizing.
class CanvasViewportTransform {
  const CanvasViewportTransform({
    required this.scale,
    required this.translateX,
    required this.translateY,
  });

  final double scale;
  final double translateX;
  final double translateY;

  CanvasViewportTransform snapTranslation(double pixelRatio) {
    final tx = (translateX * pixelRatio).roundToDouble() / pixelRatio;
    final ty = (translateY * pixelRatio).roundToDouble() / pixelRatio;

    return CanvasViewportTransform(
      scale: scale,
      translateX: tx,
      translateY: ty,
    );
  }
}

/// Contains [sourceBounds] inside the target dimensions.
///
/// This function owns only renderer-neutral viewport math. Callers choose the
/// source bounds and own policies such as artboard/content selection, padding,
/// tight output sizing, and translation snapping.
///
/// [minUniformScale] and [maxUniformScale] optionally clamp the uniform scale.
/// Translation is calculated after clamping so the source remains centred.
///
/// Nonpositive source dimensions are treated defensively as an identity
/// transform. Callers should normally avoid this by supplying valid bounds.
CanvasViewportTransform computeViewport({
  required Rect2D sourceBounds,
  required double targetW,
  required double targetH,
  double? minUniformScale,
  double? maxUniformScale,
}) {
  final srcW = sourceBounds.width;
  final srcH = sourceBounds.height;

  if (srcW <= 0 || srcH <= 0) {
    return const CanvasViewportTransform(
      scale: 1,
      translateX: 0,
      translateY: 0,
    );
  }

  final sx = targetW / srcW;
  final sy = targetH / srcH;

  var scale = sx < sy ? sx : sy;

  if (minUniformScale != null || maxUniformScale != null) {
    final lo = minUniformScale ?? double.negativeInfinity;
    final hi = maxUniformScale ?? double.infinity;
    scale = scale.clamp(lo, hi).toDouble();
  }

  final sourceCenterX =
      (sourceBounds.left + sourceBounds.right) / 2.0;
  final sourceCenterY =
      (sourceBounds.top + sourceBounds.bottom) / 2.0;

  return CanvasViewportTransform(
    scale: scale,
    translateX: targetW / 2.0 - sourceCenterX * scale,
    translateY: targetH / 2.0 - sourceCenterY * scale,
  );
}
