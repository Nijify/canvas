// Path: lib/src/runtime/viewport/canvas_viewport_policy.dart

import 'package:canvas_core/src/algorithms/viewport/viewport_math.dart'
    show CanvasFit;
import 'package:canvas_core/src/foundation/core_types.dart' show Size2D;
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;
import 'package:canvas_core/src/runtime/viewport/canvas_viewport_planner.dart'
    show CanvasViewportPlanResult, CanvasViewportPlanner;

enum CanvasViewportSource { artboard, contentBounds }

/// Generic runtime viewport policy.
///
/// This does not know about product-specific content or editor UX.
/// It only describes which world rect should be fitted into a viewport.
class CanvasViewportPolicy {
  const CanvasViewportPolicy({
    this.source = CanvasViewportSource.artboard,
    this.fit = CanvasFit.contain,
    this.paddingPx = 24,
    this.tight = false,
    this.minUniformScale,
    this.maxUniformScale,
    this.snappingEnabled = false,
    this.pixelRatioForSnapping = 1.0,
  });

  const CanvasViewportPolicy.artboard({
    CanvasFit fit = CanvasFit.contain,
    double paddingPx = 24,
    double? minUniformScale,
    double? maxUniformScale,
    bool snappingEnabled = false,
    double pixelRatioForSnapping = 1.0,
  }) : this(
         source: CanvasViewportSource.artboard,
         fit: fit,
         paddingPx: paddingPx,
         tight: false,
         minUniformScale: minUniformScale,
         maxUniformScale: maxUniformScale,
         snappingEnabled: snappingEnabled,
         pixelRatioForSnapping: pixelRatioForSnapping,
       );

  const CanvasViewportPolicy.contentBounds({
    CanvasFit fit = CanvasFit.contain,
    double paddingPx = 24,
    bool tight = false,
    double? minUniformScale,
    double? maxUniformScale,
    bool snappingEnabled = false,
    double pixelRatioForSnapping = 1.0,
  }) : this(
         source: CanvasViewportSource.contentBounds,
         fit: fit,
         paddingPx: paddingPx,
         tight: tight,
         minUniformScale: minUniformScale,
         maxUniformScale: maxUniformScale,
         snappingEnabled: snappingEnabled,
         pixelRatioForSnapping: pixelRatioForSnapping,
       );

  final CanvasViewportSource source;
  final CanvasFit fit;

  /// Viewport fitting margin.
  ///
  /// This is intentionally separate from ContentBoundsSpec.paddingPx:
  /// - ContentBoundsSpec.paddingPx expands the measured content rect.
  /// - CanvasViewportPolicy.paddingPx adds viewport margin while fitting.
  final double paddingPx;

  /// Export-style tight output sizing. Interactive editor viewports can ignore it.
  final bool tight;

  final double? minUniformScale;
  final double? maxUniformScale;

  final bool snappingEnabled;
  final double pixelRatioForSnapping;

  bool get usesContentBounds => source == CanvasViewportSource.contentBounds;

  Rect2D? boundsFor({required Rect2D? contentBounds}) {
    return usesContentBounds ? contentBounds : null;
  }

  CanvasViewportPlanResult plan({
    required Size2D artboard,
    required double targetW,
    required double targetH,
    Rect2D? contentBounds,
    double bleedPx = 0,
  }) {
    return CanvasViewportPlanner.plan(
      artboard: artboard,
      targetW: targetW,
      targetH: targetH,
      bounds: boundsFor(contentBounds: contentBounds),
      paddingPx: paddingPx,
      bleedPx: bleedPx,
      fit: fit,
      tight: tight,
      minUniformScale: minUniformScale,
      maxUniformScale: maxUniformScale,
      snappingEnabled: snappingEnabled,
      pixelRatioForSnapping: pixelRatioForSnapping,
    );
  }
}
