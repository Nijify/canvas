import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';

/// Paints ordered effects derived independently from one recorded source
/// silhouette.
///
/// The source is recorded exactly once for this operation. Every underlay reads
/// the same original source; no underlay consumes the output of another.
void paintSourceUnderlays(
  ui.Canvas canvas, {
  required List<CanvasSourceUnderlay> underlays,
  required void Function(ui.Canvas) paintSource,
}) {
  if (!underlays.any(sourceUnderlayContributesToPaint)) return;

  final recorder = ui.PictureRecorder();
  final sourceCanvas = ui.Canvas(recorder);

  late final ui.Picture source;

  try {
    paintSource(sourceCanvas);
    source = recorder.endRecording();
  } catch (_) {
    if (recorder.isRecording) {
      recorder.endRecording().dispose();
    }
    rethrow;
  }

  try {
    for (final underlay in underlays) {
      switch (underlay) {
        case ShadowEffect():
          if (!shadowContributesToPaint(underlay)) continue;
          _paintShadow(canvas, source, underlay);
      }
    }
  } finally {
    source.dispose();
  }
}

void _paintShadow(ui.Canvas canvas, ui.Picture source, ShadowEffect shadow) {
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
