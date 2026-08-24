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
    required double letterSpacing,
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
