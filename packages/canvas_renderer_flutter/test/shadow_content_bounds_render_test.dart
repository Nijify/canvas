import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

Rect2D _pixelRect(Rect2D rect) => Rect2D.fromLTRB(
  rect.left.floorToDouble(),
  rect.top.floorToDouble(),
  rect.right.ceilToDouble(),
  rect.bottom.ceilToDouble(),
);

Future<Uint8List> _render(
  CanvasRenderer renderer,
  List<PaintOp> ops,
  Rect2D viewport,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.translate(-viewport.left, -viewport.top);
  renderer.replay(canvas, ops);
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(
      viewport.width.toInt(),
      viewport.height.toInt(),
    );
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bytes == null) throw StateError('Could not read rendered pixels');
      return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final sample in <(double, double)>[
    (18, 0),
    (-18, 0),
    (18, 3),
    (-18, 3),
  ]) {
    final (offset, sigma) = sample;
    test(
      'content crop retains shadow pixels for offset $offset sigma $sigma',
      () async {
        final text = FlutterTextPipeline();
        try {
          // Ahem is the deterministic font supplied by the Flutter test harness.
          final scene = CanvasSceneDocument(
            backgroundFill: const CanvasFill.none(),
            backgroundOpacity: 1,
            children: [
              Node.text(
                id: 'text',
                data: TextData(
                  text: 'NIJIFY',
                  fontFamily: 'Ahem',
                  fontWeight: 400,
                  fontSize: 24,
                  shadows: [
                    ShadowEffect(
                      id: 's',
                      offset: Vec2(offset, offset),
                      blurSigma: sigma,
                      color: 0xFF111111,
                    ),
                  ],
                ),
              ),
            ],
          );
          final computed = computeScene(
            scene,
            CoreServices(textMeasurer: text),
          );
          final ops = buildPaintOpsFromScene(scene, computed);
          final renderer = CanvasRenderer(text: text);

          const rasterSafetyPadding = 2.0;

          final crop = _pixelRect(
            computePaddedContentBounds(
              scene: scene,
              computed: computed,
              paddingPx: rasterSafetyPadding,
            )!,
          );

          // The reference extent is independent of the proposed paint-bound map.
          final reference = _pixelRect(
            computed.layoutBoundsLocalById['text']!.inflate(128),
          );
          final cropPixels = await _render(renderer, ops, crop);
          final referencePixels = await _render(renderer, ops, reference);
          final cropWidth = crop.width.toInt();
          final cropHeight = crop.height.toInt();
          final refWidth = reference.width.toInt();
          final refHeight = reference.height.toInt();

          expect(crop.left, greaterThanOrEqualTo(reference.left));
          expect(crop.top, greaterThanOrEqualTo(reference.top));
          expect(crop.right, lessThanOrEqualTo(reference.right));
          expect(crop.bottom, lessThanOrEqualTo(reference.bottom));

          var paintedPixels = 0;
          var lostPixels = 0;
          var differentPixels = 0;
          for (var y = 0; y < refHeight; y++) {
            for (var x = 0; x < refWidth; x++) {
              final alpha = referencePixels[(y * refWidth + x) * 4 + 3];
              if (alpha > 1) paintedPixels++;
              final cx = x + (reference.left - crop.left).toInt();
              final cy = y + (reference.top - crop.top).toInt();
              if (cx < 0 || cy < 0 || cx >= cropWidth || cy >= cropHeight) {
                if (alpha > 1) lostPixels++;
                continue;
              }
              final croppedAlpha = cropPixels[(cy * cropWidth + cx) * 4 + 3];
              if ((alpha - croppedAlpha).abs() > 1) differentPixels++;
            }
          }
          expect(
            paintedPixels,
            greaterThan(0),
            reason: 'Reference must not be blank',
          );
          expect(
            lostPixels,
            0,
            reason: 'Content crop must contain reference shadow pixels',
          );
          expect(
            differentPixels,
            0,
            reason: 'Crop must preserve alpha coverage at the same scale',
          );
        } finally {
          text.dispose();
        }
      },
    );
  }
}
