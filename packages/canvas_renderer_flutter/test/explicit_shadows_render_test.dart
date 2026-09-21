import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:canvas_renderer_flutter/src/flutter_source_underlay_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

class _Icons implements IconResolver {
  @override
  ResolvedIcon? resolve(String ref) => switch (ref) {
    'glyph' => const ResolvedIconText(glyph: 'X', fontFamily: 'Ahem'),

    'path' => const ResolvedIconPath(
      PathData(source: RectSource(24, 24), strokeWidth: 0),
    ),

    'path-stroke' => const ResolvedIconPath(
      PathData(
        source: RectSource(24, 24),
        strokeColor: 0xFFFFFFFF,
        strokeWidth: 8,
      ),
    ),

    _ => null,
  };
}

const _side = 320;
const _center = _side ~/ 2;

Future<Uint8List> _pixels(void Function(ui.Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.translate(_center.toDouble(), _center.toDouble());
  paint(canvas);
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(_side, _side);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) throw StateError('No pixels');
      return Uint8List.fromList(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

int _channel(Uint8List pixels, int x, int y, int channel) =>
    pixels[((y + _center) * _side + x + _center) * 4 + channel];

Node _node(String target, List<ShadowEffect> shadows, CanvasFill foreground) =>
    target == 'text'
    ? Node.text(
        id: 'source',
        data: TextData(
          text: 'X',
          fontFamily: 'Ahem',
          fontWeight: 400,
          fontSize: 24,
          appearance: CanvasAppearance(
            foreground: foreground,
            underlays: shadows,
          ),
        ),
      )
    : Node.icon(
        id: 'source',
        data: CanvasIconData(
          iconRef: target,
          sizePx: 24,
          appearance: CanvasAppearance(
            foreground: foreground,
            underlays: shadows,
          ),
        ),
      );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final target in ['text', 'glyph', 'path']) {
    for (final sigma in [0.0, 3.0]) {
      test('$target renders independent blue shadow, sigma $sigma', () async {
        final text = FlutterTextPipeline();
        try {
          Future<Uint8List> render(
            List<ShadowEffect> shadows,
            CanvasFill fill,
          ) {
            final scene = CanvasSceneDocument(
              backgroundFill: const CanvasFill.none(),
              backgroundOpacity: 1.0,
              children: [_node(target, shadows, fill)],
            );

            final computed = computeScene(
              scene,
              CoreServices(textMeasurer: text, icons: _Icons()),
            );
            final ops = buildPaintOpsFromScene(scene, computed);
            if (target == 'path' && shadows.isNotEmpty) {
              expect(ops.whereType<DrawPathUnderlaysOp>(), hasLength(1));
            }
            return _pixels(
              (canvas) => CanvasRenderer(text: text).replay(canvas, ops),
            );
          }

          final shadow = ShadowEffect(
            id: 's',
            offset: const Vec2(80, 0),
            blurSigma: sigma,
            color: 0x800000FF,
          );
          const foreground = CanvasFill.solid(0xFFFF0000);
          final enabled = await render([shadow], foreground);
          final absent = await render([], foreground);
          final disabled = await render([
            shadow.copyWith(enabled: false),
          ], foreground);
          final transparent = await render([
            shadow.copyWith(color: 0x000000FF),
          ], foreground);
          final invisibleFill = await render([
            shadow,
          ], const CanvasFill.solid(0x00000000));
          final gradientFill = await render(
            [shadow],
            const CanvasFill.gradient(
              LinearGradientSpec(
                color1: 0xFF00FF00,
                color2: 0xFFFFFF00,
                angle: 0,
                width: 20,
              ),
            ),
          );
          expect(disabled, orderedEquals(absent));
          expect(transparent, orderedEquals(absent));

          var shadowPixels = 0;
          var softPixels = 0;
          // Source is near the origin; this region contains only its shadow.
          for (var y = -60; y <= 60; y++) {
            for (var x = 40; x <= 120; x++) {
              final alpha = _channel(enabled, x, y, 3);
              expect(_channel(absent, x, y, 3), 0);
              for (var c = 0; c < 4; c++) {
                expect(
                  _channel(invisibleFill, x, y, c),
                  _channel(enabled, x, y, c),
                );
                expect(
                  _channel(gradientFill, x, y, c),
                  _channel(enabled, x, y, c),
                );
              }
              if (alpha > 1) {
                shadowPixels++;
                expect(
                  _channel(enabled, x, y, 2),
                  greaterThan(_channel(enabled, x, y, 0)),
                );
              }
              if (alpha > 1 && alpha < 120) softPixels++;
              expect(alpha, lessThanOrEqualTo(129));
            }
          }
          expect(shadowPixels, greaterThan(0));
          if (sigma > 0) expect(softPixels, greaterThan(0));
        } finally {
          text.dispose();
        }
      });
    }
  }

  for (final target in ['text', 'glyph', 'path']) {
    test('$target renders shadow-only appearance without foreground', () async {
      final text = FlutterTextPipeline();

      try {
        const shadow = ShadowEffect(
          id: 'shadow-only',
          offset: Vec2(80, 0),
          color: 0xFF0000FF,
        );

        final scene = CanvasSceneDocument(
          backgroundFill: const CanvasFill.none(),
          backgroundOpacity: 1,
          children: [
            _node(target, const [shadow], const CanvasFill.none()),
          ],
        );

        final computed = computeScene(
          scene,
          CoreServices(textMeasurer: text, icons: _Icons()),
        );

        final ops = buildPaintOpsFromScene(scene, computed);

        final pixels = await _pixels(
          (canvas) => CanvasRenderer(text: text).replay(canvas, ops),
        );

        var sourcePixels = 0;

        for (var y = -35; y <= 35; y++) {
          for (var x = -35; x <= 35; x++) {
            if (_channel(pixels, x, y, 3) != 0) {
              sourcePixels++;
            }
          }
        }

        expect(
          sourcePixels,
          0,
          reason: 'foreground must not fall back to black',
        );

        var shadowPixels = 0;

        for (var y = -40; y <= 60; y++) {
          for (var x = 50; x <= 120; x++) {
            if (_channel(pixels, x, y, 3) != 0) {
              shadowPixels++;
            }
          }
        }

        expect(shadowPixels, greaterThan(0));
      } finally {
        text.dispose();
      }
    });
  }

  test(
    'path fill and intrinsic stroke contribute to source silhouette',
    () async {
      final text = FlutterTextPipeline();

      try {
        final path = PathIR(
          [
            PathCmd.moveTo(const Vec2(-10, -10)),
            PathCmd.lineTo(const Vec2(10, -10)),
            PathCmd.lineTo(const Vec2(10, 10)),
            PathCmd.lineTo(const Vec2(-10, 10)),
            PathCmd.close(),
          ],
          const PathStyle(fill: 0xFFFFFFFF, stroke: 0xFFFFFFFF, strokeWidth: 8),
        );

        final op = DrawPathUnderlaysOp(path, const [
          ShadowEffect(id: 's', offset: Vec2(50, 0), color: 0x800000FF),
        ]);

        final pixels = await _pixels(
          (canvas) => CanvasRenderer(text: text).replay(canvas, [op]),
        );

        // Filled interior.
        expect(_channel(pixels, 50, 0, 3), closeTo(128, 1));

        // Stroke-only coverage:
        // fill ends at local x=10; 8px stroke extends to x=14.
        expect(_channel(pixels, 63, 0, 3), closeTo(128, 1));
      } finally {
        text.dispose();
      }
    },
  );

  test(
    'path icon none foreground suppresses intrinsic fill and stroke',
    () async {
      final text = FlutterTextPipeline();

      try {
        final scene = CanvasSceneDocument(
          backgroundFill: const CanvasFill.none(),
          backgroundOpacity: 1,
          children: const [
            Node.icon(
              id: 'source',
              data: CanvasIconData(
                iconRef: 'path-stroke',
                sizePx: 24,
                appearance: CanvasAppearance(
                  foreground: CanvasFill.none(),
                  underlays: [
                    ShadowEffect(
                      id: 'shadow',
                      offset: Vec2(70, 0),
                      color: 0xFF0000FF,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

        final computed = computeScene(
          scene,
          CoreServices(textMeasurer: text, icons: _Icons()),
        );

        final ops = buildPaintOpsFromScene(scene, computed);

        expect(ops.whereType<DrawPathUnderlaysOp>(), hasLength(1));

        expect(ops.whereType<FillPathOp>(), isEmpty);
        expect(ops.whereType<FillPathGradientOp>(), isEmpty);
        expect(ops.whereType<StrokePathOp>(), isEmpty);

        final pixels = await _pixels(
          (canvas) => CanvasRenderer(text: text).replay(canvas, ops),
        );

        // Nothing from the authored foreground may remain around the source.
        var sourcePixels = 0;

        for (var y = -30; y <= 30; y++) {
          for (var x = -30; x <= 30; x++) {
            if (_channel(pixels, x, y, 3) != 0) {
              sourcePixels++;
            }
          }
        }

        expect(sourcePixels, 0);

        // But the displaced shadow, including intrinsic-stroke coverage,
        // must still exist.
        var shadowPixels = 0;

        for (var y = -40; y <= 40; y++) {
          for (var x = 45; x <= 110; x++) {
            if (_channel(pixels, x, y, 3) != 0) {
              shadowPixels++;
            }
          }
        }

        expect(shadowPixels, greaterThan(0));
      } finally {
        text.dispose();
      }
    },
  );

  test('list order is back-to-front and source is recorded once', () async {
    const red = ShadowEffect(id: 'r', offset: Vec2(50, 0), color: 0x80FF0000);
    const blue = ShadowEffect(id: 'b', offset: Vec2(50, 0), color: 0x800000FF);
    var sourceCalls = 0;
    Future<Uint8List> render(List<ShadowEffect> shadows) => _pixels(
      (canvas) => paintSourceUnderlays(
        canvas,
        underlays: shadows,
        paintSource: (source) {
          sourceCalls++;
          source.drawRect(
            const ui.Rect.fromLTWH(-10, -10, 20, 20),
            ui.Paint()..color = const ui.Color(0xFF000000),
          );
        },
      ),
    );
    final blueOnTop = await render([red, blue]);
    expect(sourceCalls, 1);
    final redOnTop = await render([blue, red]);
    expect(sourceCalls, 2);
    expect(
      _channel(blueOnTop, 50, 0, 2),
      greaterThan(_channel(blueOnTop, 50, 0, 0)),
    );
    expect(
      _channel(redOnTop, 50, 0, 0),
      greaterThan(_channel(redOnTop, 50, 0, 2)),
    );
    expect(_channel(blueOnTop, 50, 0, 3), closeTo(192, 1));
    // A chained shadow would incorrectly create coverage at x = 100.
    expect(_channel(blueOnTop, 100, 0, 3), 0);
    await render([]);
    await render([red.copyWith(enabled: false)]);
    expect(sourceCalls, 2);
  });
}
