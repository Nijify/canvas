// Path: oss_packages/canvas_core/lib/src/runtime/viewport/canvas_viewport_planner.dart

import 'dart:math' as math;
import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/algorithms/viewport/viewport_math.dart'
    show
        CanvasViewportTransform,
        CanvasFit,
        computeViewport,
        computeViewportWithPadding;
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;

/// Extra sizing info for export tight mode.
class CanvasViewportPlanResult {
  const CanvasViewportPlanResult({
    required this.transform,
    required this.outputW,
    required this.outputH,
  });

  final CanvasViewportTransform transform;

  /// Final logical output size (pre pixelRatio) used for recordingW/H math.
  final double outputW;
  final double outputH;
}

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
  static CanvasViewportPlanResult plan({
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

    // Padding path: use computeViewportWithPadding (inner padding).
    // Bleed path: use computeViewport with bleed (outer margin).
    final CanvasViewportTransform t = (paddingPx > 0)
        ? computeViewportWithPadding(
            artboardW: artboard.w,
            artboardH: artboard.h,
            viewportW: outW,
            viewportH: outH,
            bounds: bounds,
            paddingPx: paddingPx,
            fit: fit,
            minUniformScale: minUniformScale,
            maxUniformScale: maxUniformScale,
          )
        : computeViewport(
            artboardW: artboard.w,
            artboardH: artboard.h,
            targetW: outW,
            targetH: outH,
            bounds: bounds,
            bleed: bleedPx,
            fit: fit,
            minUniformScale: minUniformScale,
            maxUniformScale: maxUniformScale,
          );

    final snapped = snappingEnabled
        ? t.snapTranslation(pixelRatioForSnapping)
        : t;

    return CanvasViewportPlanResult(
      transform: snapped,
      outputW: outW,
      outputH: outH,
    );
  }
}
