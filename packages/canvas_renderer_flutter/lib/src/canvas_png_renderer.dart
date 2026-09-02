// Path: lib/src/canvas_png_renderer.dart

import 'dart:typed_data';

import 'package:canvas_core/canvas_core_runtime.dart';

/// Output configuration for canonical PNG rendering.
final class CanvasPngSpec {
  const CanvasPngSpec({
    required this.widthPx,
    required this.heightPx,
    this.bleedPx = 0,
    this.pixelRatio = 2.0,
    this.transparent = true,
    this.fit = CanvasFit.contain,
    this.cropToContent = false,
    this.contentPaddingPx = 0,
    this.tight = false,
    this.contentBoundsPolicy,
  });

  final int widthPx;
  final int heightPx;
  final int bleedPx;
  final double pixelRatio;
  final bool transparent;
  final CanvasFit fit;

  /// Computes content bounds from the prepared final scene and uses those
  /// bounds as the export viewport.
  final bool cropToContent;

  /// Additional document-space padding around computed content bounds.
  final double contentPaddingPx;

  /// When cropping to content, allows the output dimensions to tighten around
  /// the computed bounds while remaining within [widthPx] and [heightPx].
  final bool tight;

  /// Optional generic content-selection policy used for content bounds.
  final ContentBoundsPolicy? contentBoundsPolicy;
}

/// Canonical final-output PNG rendering boundary.
///
/// Implementations receive an unresolved-for-rendering but otherwise canonical
/// runtime scene. Scene preparation, resource preflight, layout, painting, and
/// PNG encoding belong behind this boundary.
abstract interface class CanvasPngRenderer {
  Future<Uint8List> renderPng({
    required CanvasSceneDocument scene,
    required CanvasPngSpec spec,
  });
}
