// Path: lib/src/algorithms/viewport/viewport_math.dart

import 'dart:math' as math;
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;

enum CanvasFit { contain, cover, stretch }

class CanvasViewportTransform {
  const CanvasViewportTransform({
    required this.scaleX,
    required this.scaleY,
    required this.translateX,
    required this.translateY,
    required this.recordingW,
    required this.recordingH,
  });

  final double scaleX, scaleY;
  final double translateX, translateY;
  final double recordingW, recordingH;

  CanvasViewportTransform snapTranslation(double pixelRatio) {
    final tx = (translateX * pixelRatio).roundToDouble() / pixelRatio;
    final ty = (translateY * pixelRatio).roundToDouble() / pixelRatio;
    return CanvasViewportTransform(
      scaleX: scaleX,
      scaleY: scaleY,
      translateX: tx,
      translateY: ty,
      recordingW: recordingW,
      recordingH: recordingH,
    );
  }
}

/// Fits either the artboard (bounds=null) or a world-space bounds rect into a target,
/// with optional "bleed" (outer margin).
CanvasViewportTransform computeViewport({
  required double artboardW,
  required double artboardH,
  required double targetW,
  required double targetH,
  Rect2D? bounds, // if set: fit this rect in artboard coordinates
  double bleed = 0,
  CanvasFit fit = CanvasFit.contain,

  // Optional clamp used by editor camera (export doesn’t need this).
  double? minUniformScale,
  double? maxUniformScale,
}) {
  // Source rect
  final double srcW, srcH, srcLeft, srcTop;

  if (bounds != null) {
    srcW = (bounds.right - bounds.left).abs();
    srcH = (bounds.bottom - bounds.top).abs();
    srcLeft = bounds.left;
    srcTop = bounds.top;
  } else {
    srcW = artboardW;
    srcH = artboardH;
    srcLeft = 0;
    srcTop = 0;
  }

  if (srcW <= 0 || srcH <= 0) {
    return CanvasViewportTransform(
      scaleX: 1,
      scaleY: 1,
      translateX: bleed,
      translateY: bleed,
      recordingW: targetW + bleed * 2,
      recordingH: targetH + bleed * 2,
    );
  }

  final sx = targetW / srcW;
  final sy = targetH / srcH;

  final base = switch (fit) {
    CanvasFit.contain => sx < sy ? sx : sy,
    CanvasFit.cover => sx > sy ? sx : sy,
    CanvasFit.stretch => 1.0,
  };

  var scaleX = fit == CanvasFit.stretch ? sx : base;
  var scaleY = fit == CanvasFit.stretch ? sy : base;

  // Editor clamp (uniform only; stretch shouldn’t clamp like this)
  if (fit != CanvasFit.stretch &&
      (minUniformScale != null || maxUniformScale != null)) {
    final lo = minUniformScale ?? double.negativeInfinity;
    final hi = maxUniformScale ?? double.infinity;
    final clamped = base.clamp(lo, hi).toDouble();
    scaleX = clamped;
    scaleY = clamped;
  }

  final scaledW = srcW * scaleX;
  final scaledH = srcH * scaleY;

  final dx = bleed + (targetW - scaledW) / 2.0 - srcLeft * scaleX;
  final dy = bleed + (targetH - scaledH) / 2.0 - srcTop * scaleY;

  return CanvasViewportTransform(
    scaleX: scaleX,
    scaleY: scaleY,
    translateX: dx,
    translateY: dy,
    recordingW: targetW + bleed * 2,
    recordingH: targetH + bleed * 2,
  );
}

CanvasViewportTransform computeViewportWithPadding({
  required double artboardW,
  required double artboardH,
  required double viewportW,
  required double viewportH,
  Rect2D? bounds,
  double paddingPx = 0,
  CanvasFit fit = CanvasFit.contain,
  double? minUniformScale,
  double? maxUniformScale,
}) {
  final targetW = math.max(1.0, viewportW - paddingPx * 2);
  final targetH = math.max(1.0, viewportH - paddingPx * 2);

  return computeViewport(
    artboardW: artboardW,
    artboardH: artboardH,
    targetW: targetW,
    targetH: targetH,
    bounds: bounds,
    bleed: paddingPx,
    fit: fit,
    minUniformScale: minUniformScale,
    maxUniformScale: maxUniformScale,
  );
}
