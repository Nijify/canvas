import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';

/// Operation-scoped silhouette reuse; no persistent GPU cache is introduced.
/// The callback paints source coverage in local coordinates with opaque
/// ordinary text/path paints, without the authored foreground fill.
void paintSourceShadows(
  ui.Canvas canvas, {
  required List<ShadowEffect> shadows,
  required void Function(ui.Canvas) paintSource,
}) {
  if (!shadows.any(shadowContributesToPaint)) return;

  final recorder = ui.PictureRecorder();
  final sourceCanvas = ui.Canvas(recorder);
  late final ui.Picture source;
  try {
    paintSource(sourceCanvas);
    source = recorder.endRecording();
  } catch (_) {
    if (recorder.isRecording) recorder.endRecording().dispose();
    rethrow;
  }

  try {
    for (final shadow in shadows) {
      if (!shadowContributesToPaint(shadow)) continue;
      final layerPaint = ui.Paint()
        ..colorFilter = ui.ColorFilter.mode(
          ui.Color(shadow.color),
          ui.BlendMode.srcIn,
        );
      if (shadow.blurSigma > 0) {
        layerPaint.imageFilter = ui.ImageFilter.blur(
          sigmaX: shadow.blurSigma,
          sigmaY: shadow.blurSigma,
          tileMode: ui.TileMode.decal,
        );
      }

      canvas.save();
      try {
        canvas.translate(shadow.offset.x, shadow.offset.y);
        // Do not use metric-based paint estimates as a hard layer bound.
        // The current target clip still applies; callers must allow shadow
        // extent when choosing their viewport/export crop.
        canvas.saveLayer(null, layerPaint);
        try {
          canvas.drawPicture(source);
        } finally {
          canvas.restore();
        }
      } finally {
        canvas.restore();
      }
    }
  } finally {
    source.dispose();
  }
}
