// Path: packages/canvas_renderer_flutter/test/path_authored_style_render_test.dart

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

const _side = 64;
const _center = _side ~/ 2;

Future<({Uint8List pixels, Rect2D? paintBounds})> _render(PathData data) async {
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
        return (
          pixels: Uint8List.fromList(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          ),
          paintBounds: evaluation.computed.paintBoundsLocalById['path'],
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
    final render = await _render(
      PathData(
        source: GeneralPathSource.fromSvg(
          'M-12 -12 L12 -12 L12 12 L-12 12 L-12 -12 '
          'M-5 -5 L5 -5 L5 5 L-5 5 L-5 -5',
        ),
        fillRule: FillRule.evenOdd,
        appearance: CanvasAppearance(
          foreground: const CanvasFill.solid(0xFFFF0000),
          stroke: CanvasStroke(color: 0xFF0000FF, width: 4),
        ),
      ),
    );

    expect(_rgba(render.pixels, 0, 0), [0, 0, 0, 0]);
    expect(_rgba(render.pixels, 8, 0), [255, 0, 0, 255]);
    expect(_rgba(render.pixels, 12, 0), [0, 0, 255, 255]);
    expect(_rgba(render.pixels, 16, 0), [0, 0, 0, 0]);
  });

  test('ordinary path stroke width and cap come from CanvasStroke', () async {
    final render = await _render(
      PathData(
        source: const LineSource(x1: -8, x2: 8),
        appearance: CanvasAppearance(
          foreground: const CanvasFill.none(),
          stroke: CanvasStroke(
            color: 0xFF203040,
            width: 6,
            cap: StrokeCap.round,
          ),
        ),
      ),
    );

    expect(_rgba(render.pixels, 9, 0), [32, 48, 64, 255]);
    expect(_rgba(render.pixels, 0, 2), [32, 48, 64, 255]);
    expect(_rgba(render.pixels, 0, 4), [0, 0, 0, 0]);
  });

  for (final (name, data) in [
    (
      'square caps',
      PathData(
        source: PolylineSource(const [Vec2(-8, -8), Vec2(8, 8)]),
        appearance: CanvasAppearance(
          foreground: const CanvasFill.none(),
          stroke: CanvasStroke(
            color: 0xFF112233,
            width: 8,
            cap: StrokeCap.square,
            join: StrokeJoin.bevel,
          ),
        ),
      ),
    ),
    (
      'acute miter',
      PathData(
        source: PolylineSource(const [Vec2(-4, 10), Vec2(0, -10), Vec2(4, 10)]),
        appearance: CanvasAppearance(
          foreground: const CanvasFill.none(),
          stroke: CanvasStroke(color: 0xFF112233, width: 6, miterLimit: 6),
        ),
      ),
    ),
  ]) {
    test('$name paint stays within the estimate plus raster padding', () async {
      final render = await _render(data);
      expect(render.paintBounds, isNotNull);
      final padded = render.paintBounds!.inflate(1);
      final points = (data.source as PolylineSource).points;
      final geometry = PathIR([
        for (final (index, point) in points.indexed)
          index == 0 ? PathCmd.moveTo(point) : PathCmd.lineTo(point),
      ]).localBounds();
      final halfWidthBounds = geometry.inflate(
        data.appearance.stroke!.width / 2,
      );
      var paintedPixels = 0;
      var paintedBeyondHalfWidth = false;
      for (var y = 0; y < _side; y++) {
        for (var x = 0; x < _side; x++) {
          if (render.pixels[(y * _side + x) * 4 + 3] == 0) continue;
          final point = Vec2(x - _center + 0.5, y - _center + 0.5);
          expect(padded.contains(point), isTrue, reason: '$name at $point');
          paintedPixels++;
          if (!halfWidthBounds.contains(point)) paintedBeyondHalfWidth = true;
        }
      }
      expect(paintedPixels, greaterThan(0));
      expect(paintedBeyondHalfWidth, isTrue);
    });
  }
}
