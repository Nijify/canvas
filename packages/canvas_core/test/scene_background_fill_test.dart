// Path: test/scene_background_fill_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

class _FakeTextMeasurer implements TextMeasurer {
  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required int letterSpacing,
  }) {
    return const Size2D(0, 0);
  }
}

CanvasSceneDocument _scene({
  required CanvasFill backgroundFill,
  required double backgroundOpacity,
}) {
  return CanvasSceneDocument(
    backgroundFill: backgroundFill,
    backgroundOpacity: backgroundOpacity,
  );
}

List<PaintOp> _paintOps({
  required CanvasFill backgroundFill,
  required double backgroundOpacity,
}) {
  final scene = _scene(
    backgroundFill: backgroundFill,
    backgroundOpacity: backgroundOpacity,
  );

  final computed = computeScene(scene, CoreServices(tm: _FakeTextMeasurer()));

  return buildPaintOpsFromScene(scene, computed);
}

void main() {
  group('CanvasSceneDocument background contract', () {
    test('round-trips explicit background fill and opacity', () {
      const fill = CanvasFill.gradient(
        LinearGradientSpec(
          color1: 0xFF112233,
          color2: 0x80445566,
          angle: 45,
          width: 20,
        ),
      );

      final scene = _scene(backgroundFill: fill, backgroundOpacity: 0.5);

      final json = scene.toJson();

      expect(
        json['backgroundFill'],
        equals({
          'type': 'gradient',
          'grad': {
            'color1': 0xFF112233,
            'color2': 0x80445566,
            'angle': 45.0,
            'width': 20.0,
          },
        }),
      );
      expect(json['backgroundOpacity'], 0.5);

      expect(json.containsKey('bgGradient'), isFalse);
      expect(json.containsKey('bgOpacity'), isFalse);

      final restored = CanvasSceneDocument.fromJson(json);

      expect(restored, scene);
      expect(
        restored.copyWith(
          backgroundFill: const CanvasFill.none(),
          backgroundOpacity: 0.8,
        ),
        isNot(scene),
      );
    });

    test('rejects missing required background fields', () {
      final base = <String, dynamic>{
        'artboardSize': {'w': 740.0, 'h': 360.0},
        'backgroundFill': {'type': 'none'},
        'backgroundOpacity': 1.0,
        'children': <dynamic>[],
      };

      final missingFill = Map<String, dynamic>.from(base)
        ..remove('backgroundFill');

      final missingOpacity = Map<String, dynamic>.from(base)
        ..remove('backgroundOpacity');

      expect(
        () => CanvasSceneDocument.fromJson(missingFill),
        throwsA(anything),
      );

      expect(
        () => CanvasSceneDocument.fromJson(missingOpacity),
        throwsA(anything),
      );
    });

    test('rejects a legacy-only background payload', () {
      final legacy = <String, dynamic>{
        'artboardSize': {'w': 740.0, 'h': 360.0},
        'bgGradient': {'color1': 0, 'color2': 0, 'angle': 0.0, 'width': 0.0},
        'bgOpacity': 0.0,
        'children': <dynamic>[],
      };

      expect(() => CanvasSceneDocument.fromJson(legacy), throwsA(anything));
    });
  });

  group('scene background paint planning', () {
    test('none emits no background paint operation', () {
      final ops = _paintOps(
        backgroundFill: const CanvasFill.none(),
        backgroundOpacity: 1.0,
      );

      expect(ops.whereType<FillRectOp>(), isEmpty);
      expect(ops.whereType<FillRectGradientOp>(), isEmpty);
      expect(ops, isEmpty);
    });

    test('solid emits FillRectOp with multiplied alpha', () {
      final ops = _paintOps(
        backgroundFill: const CanvasFill.solid(0xFF112233),
        backgroundOpacity: 0.5,
      );

      expect(ops, hasLength(1));
      expect(ops.single, isA<FillRectOp>());

      final op = ops.single as FillRectOp;

      expect(op.color, 0x80112233);
    });

    test('gradient emits FillRectGradientOp with multiplied alpha', () {
      final ops = _paintOps(
        backgroundFill: const CanvasFill.gradient(
          LinearGradientSpec(
            color1: 0xFF112233,
            color2: 0x80445566,
            angle: 0,
            width: 20,
          ),
        ),
        backgroundOpacity: 0.5,
      );

      expect(ops, hasLength(1));
      expect(ops.single, isA<FillRectGradientOp>());

      final op = ops.single as FillRectGradientOp;

      expect(op.gradient.colors, <int>[0x80112233, 0x40445566]);
    });

    test('zero opacity emits no background paint operation', () {
      final ops = _paintOps(
        backgroundFill: const CanvasFill.solid(0xFF112233),
        backgroundOpacity: 0.0,
      );

      expect(ops, isEmpty);
    });
  });
}
