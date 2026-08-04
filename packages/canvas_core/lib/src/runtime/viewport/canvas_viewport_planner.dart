// Path: lib/src/runtime/viewport/canvas_viewport_planner.dart

import 'dart:math' as math;
import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/algorithms/viewport/viewport_math.dart'
    show CanvasViewportTransform, CanvasFit, computeViewport;
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;

abstract final class CanvasViewportPlanner {
  /// Plan a viewport transform for editor/thumb/export.
  ///
  /// - If [bounds] is provided, viewport fits bounds instead of artboard.
  /// - [paddingPx] is used for editor/thumb (inner padding).
  /// - [bleedPx] is used for export (outer bleed margin).
  /// - If [tight] and bounds is present: output size becomes bounds-tight,
  ///   scaled up to fit within max [targetW]/[targetH].
  ///
  /// Snapping:
  /// - Controlled by [snappingEnabled].
  /// - Export default MUST pass snappingEnabled=false (mathematically exact).
  ///   TODO: future "sharp as possible" export mode can enable snapping.
  static CanvasViewportTransform plan({
    required Size2D artboard,
    required double targetW,
    required double targetH,
    Rect2D? bounds,
    double paddingPx = 0,
    double bleedPx = 0,
    CanvasFit fit = CanvasFit.contain,
    double? minUniformScale,
    double? maxUniformScale,
    bool tight = false,
    bool snappingEnabled = false,
    double pixelRatioForSnapping = 1.0,
  }) {
    var outW = targetW;
    var outH = targetH;

    // Tight sizing (export) only makes sense with bounds.
    if (tight && bounds != null) {
      final bw = bounds.width;
      final bh = bounds.height;

      if (bw > 0 && bh > 0) {
        final s = math.min(targetW / bw, targetH / bh);
        outW = bw * s;
        outH = bh * s;
      }
    }

    final hasPadding = paddingPx > 0;
    final viewportW = hasPadding
        ? math.max(1.0, outW - paddingPx * 2)
        : outW;
    final viewportH = hasPadding
        ? math.max(1.0, outH - paddingPx * 2)
        : outH;

    final t = computeViewport(
      artboardW: artboard.w,
      artboardH: artboard.h,
      targetW: viewportW,
      targetH: viewportH,
      bounds: bounds,
      bleed: hasPadding ? paddingPx : bleedPx,
      fit: fit,
      minUniformScale: minUniformScale,
      maxUniformScale: maxUniformScale,
    );

    final snapped = snappingEnabled
        ? t.snapTranslation(pixelRatioForSnapping)
        : t;

    return snapped;
  }
}
