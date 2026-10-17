// Path: packages/canvas_renderer_flutter/test/path_authored_style_render_test.dart

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

const _side = 64;
const _center = _side ~/ 2;

Future<Uint8List> _pixels(PathData data) async {
  final text = FlutterTextPipeline();
  try {
    final scene = CanvasSceneDocument(
      artboardSize: const Size2D(_side * 1.0, _side * 1.0),
      backgroundFill: const CanvasFill.none(),
      backgroundOpacity: 1,
      children: [
        Node.path(
          id: 'path',
          xf: const Transform2D(position: Vec2(_center * 1.0, _center * 1.0)),
          data: data,
        ),
      ],
    );
    final evaluation = evaluateScene(scene, CoreServices(textMeasurer: text));

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    CanvasRenderer(text: text).paintScene(canvas, evaluation);
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(_side, _side);
      try {
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        if (bytes == null) throw StateError('Unable to read pixels.');
        return Uint8List.fromList(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
      } finally {
        image.dispose();
      }
    } finally {
      picture.dispose();
    }
  } finally {
    text.dispose();
  }
}

List<int> _rgba(Uint8List pixels, int x, int y) {
  final offset = ((y + _center) * _side + x + _center) * 4;
  return pixels.sublist(offset, offset + 4);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ordinary path uses its fill rule and shared appearance', () async {
    final pixels = await _pixels(
      PathData(
        source: PolylineSource(const [
          Vec2(-12, -12),
          Vec2(12, -12),
          Vec2(12, 12),
          Vec2(-12, 12),
          Vec2(-12, -12),
          null,
          Vec2(-5, -5),
          Vec2(5, -5),
          Vec2(5, 5),
          Vec2(-5, 5),
          Vec2(-5, -5),
        ]),
        fillRule: FillRule.evenOdd,
        appearance: const CanvasAppearance(
          foreground: CanvasFill.solid(0xFFFF0000),
          stroke: CanvasStroke(color: 0xFF0000FF, width: 4),
        ),
      ),
    );

    expect(_rgba(pixels, 0, 0), [0, 0, 0, 0]);
    expect(_rgba(pixels, 8, 0), [255, 0, 0, 255]);
    expect(_rgba(pixels, 12, 0), [0, 0, 255, 255]);
    expect(_rgba(pixels, 16, 0), [0, 0, 0, 0]);
  });

  test('ordinary path stroke width and cap come from CanvasStroke', () async {
    final pixels = await _pixels(
      PathData(
        source: PolylineSource(const [Vec2(-8, 0), Vec2(8, 0)]),
        appearance: const CanvasAppearance(
          foreground: CanvasFill.none(),
          stroke: CanvasStroke(
            color: 0xFF203040,
            width: 6,
            cap: StrokeCap.round,
          ),
        ),
      ),
    );

    expect(_rgba(pixels, 9, 0), [32, 48, 64, 255]);
    expect(_rgba(pixels, 0, 2), [32, 48, 64, 255]);
    expect(_rgba(pixels, 0, 4), [0, 0, 0, 0]);
  });
}
