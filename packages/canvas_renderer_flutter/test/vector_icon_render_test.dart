import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

const _side = 160;
const _center = _side ~/ 2;

List<PathCmd> _rect(Rect2D box, {bool reverse = false}) {
  final corners = [
    Vec2(box.left, box.top),
    Vec2(box.right, box.top),
    Vec2(box.right, box.bottom),
    Vec2(box.left, box.bottom),
  ];
  final points = reverse ? corners.reversed.toList() : corners;
  return [
    PathCmd.moveTo(points.first),
    for (final point in points.skip(1)) PathCmd.lineTo(point),
    PathCmd.close(),
  ];
}

ResolvedIcon _icon({
  List<PathCmd>? commands,
  Rect2D box = const Rect2D(0, 0, 24, 24),
  FillRule fillRule = FillRule.nonZero,
}) => ResolvedIcon(
  pathIR: PathIR(commands ?? _rect(box)),
  viewBox: box,
  fillRule: fillRule,
);

class _Icons implements IconResolver {
  _Icons(this.icon);
  final ResolvedIcon icon;
  int calls = 0;
  bool evaluated = false;
  @override
  ResolvedIcon? resolve(String ref) {
    if (evaluated) throw StateError('Painting must use the evaluated icon.');
    calls++;
    return icon;
  }
}

Future<Uint8List> _render(
  ResolvedIcon icon, {
  double size = 48,
  CanvasAppearance appearance = const CanvasAppearance(),
  Affine2D parent = const Affine2D.identity(),
}) async {
  final text = FlutterTextPipeline();
  try {
    final icons = _Icons(icon);
    final scene = CanvasSceneDocument(
      artboardSize: const Size2D(_side * 1.0, _side * 1.0),
      backgroundFill: const CanvasFill.none(),
      backgroundOpacity: 1,
      children: [
        Node.group(
          id: 'frame',
          xf: Affine2D.translation(_center * 1.0, _center * 1.0) * parent,
          children: [
            Node.icon(
              id: 'icon',
              data: CanvasIconData(
                iconRef: 'test',
                sizePx: size,
                appearance: appearance,
              ),
            ),
          ],
        ),
      ],
    );
    final evaluation = evaluateScene(
      scene,
      CoreServices(textMeasurer: text, icons: icons),
    );
    expect(icons.calls, 1);
    icons.evaluated = true;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    CanvasRenderer(text: text).paintScene(canvas, evaluation);
    expect(icons.calls, 1);
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(_side, _side);
      try {
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        if (bytes == null) throw StateError('No icon pixels.');
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
  final index = ((y + _center) * _side + x + _center) * 4;
  return pixels.sublist(index, index + 4);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('solid foreground recolors fitted non-square geometry', () async {
    final pixels = await _render(
      _icon(box: const Rect2D(10, -8, 42, 8)),
      appearance: const CanvasAppearance(
        foreground: CanvasFill.solid(0xff123456),
      ),
    );
    expect(_rgba(pixels, 0, 0), [18, 52, 86, 255]);
    expect(_rgba(pixels, 22, 0), [18, 52, 86, 255]);
    expect(_rgba(pixels, 0, 16)[3], 0);
    expect(_rgba(pixels, 25, 0)[3], 0);
  });

  test('fill rules preserve holes in compound silhouettes', () async {
    const box = Rect2D(10, -8, 42, 8);
    for (final rule in FillRule.values) {
      final pixels = await _render(
        _icon(
          box: box,
          fillRule: rule,
          commands: [
            ..._rect(box),
            ..._rect(
              const Rect2D(22, -4, 30, 4),
              reverse: rule == FillRule.nonZero,
            ),
          ],
        ),
      );
      expect(_rgba(pixels, 0, 0)[3], 0);
      expect(_rgba(pixels, -15, 0)[3], 255);
    }
    final filled = await _render(
      _icon(
        box: box,
        commands: [..._rect(box), ..._rect(const Rect2D(22, -4, 30, 4))],
      ),
    );
    expect(_rgba(filled, 0, 0)[3], 255);
  });

  test('overlapping contours receive foreground alpha once', () async {
    final pixels = await _render(
      _icon(
        commands: [
          ..._rect(const Rect2D(0, 0, 16, 24)),
          ..._rect(const Rect2D(8, 0, 24, 24)),
        ],
      ),
      appearance: const CanvasAppearance(
        foreground: CanvasFill.solid(0x80ff0000),
      ),
    );
    for (final x in [-18, 0, 18]) {
      expect(_rgba(pixels, x, 0)[3], 128);
      expect(_rgba(pixels, x, 0)[1], 0);
      expect(_rgba(pixels, x, 0)[2], 0);
    }
  });

  test('gradient endpoints stay in node-local coordinates', () async {
    final pixels = await _render(
      _icon(),
      appearance: CanvasAppearance(
        foreground: CanvasFill.gradient(
          LinearGradientSpec(
            start: const Vec2(-24, 0),
            end: const Vec2(24, 0),
            stops: const [
              GradientStop(offset: 0, color: 0xffff0000),
              GradientStop(offset: 1, color: 0xff0000ff),
            ],
          ),
        ),
      ),
    );
    final left = _rgba(pixels, -18, 0), right = _rgba(pixels, 18, 0);
    expect(left[0], greaterThan(180));
    expect(left[2], lessThan(75));
    expect(right[0], lessThan(75));
    expect(right[2], greaterThan(180));
  });

  test('shadow-only appearance keeps offset and blur in local units', () async {
    final softEdge = <int>[];
    for (final size in [24.0, 48.0]) {
      final pixels = await _render(
        _icon(),
        size: size,
        appearance: const CanvasAppearance(
          foreground: CanvasFill.none(),
          underlays: [
            ShadowEffect(
              id: 's',
              offset: Vec2(40, 0),
              blurSigma: 3,
              color: 0xff0000ff,
            ),
          ],
        ),
      );
      expect(_rgba(pixels, 0, 0)[3], 0);
      expect(_rgba(pixels, 40, 0)[2], greaterThan(245));
      softEdge.add(_rgba(pixels, 40 + size ~/ 2 + 3, 0)[3]);
    }
    expect(softEdge.first, greaterThan(0));
    expect(softEdge.first, lessThan(100));
    expect(softEdge.last, closeTo(softEdge.first, 3));
  });

  test('parent transforms apply after the source fit', () async {
    final pixels = await _render(
      _icon(box: const Rect2D(0, 0, 32, 16)),
      parent: (Affine2D.rotation(math.pi / 2) * Affine2D.scale(2, 1)),
    );
    expect(_rgba(pixels, 0, 40)[3], 255);
    expect(_rgba(pixels, 20, 0)[3], 0);
  });

  test('the layout square does not clip filled source geometry', () async {
    final pixels = await _render(
      _icon(commands: _rect(const Rect2D(-4, -4, 28, 28))),
    );
    expect(_rgba(pixels, 28, 0)[3], 255);
    expect(_rgba(pixels, 34, 0)[3], 0);
  });
}
