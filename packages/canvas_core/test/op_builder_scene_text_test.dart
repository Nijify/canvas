// Path: test/op_builder_scene_text_test.dart
import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/foundation/paint/canvas_fill.dart';
import 'package:canvas_core/src/render_plan/paint_ops.dart';
import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/render_plan/op_builder_scene.dart';
import 'package:canvas_core/src/runtime/model/scene_document.dart';
import 'package:canvas_core/src/runtime/model/canvas_appearance.dart';
import 'package:canvas_core/src/services/services.dart';
import 'package:canvas_core/src/services/services_context.dart';
import 'package:canvas_core/src/algorithms/layout/computed_scene.dart'
    show computeScene;
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
    final w = text.length.toDouble() * (fontSize * 0.5);
    final h = fontSize;
    return Size2D(w, h);
  }
}

class _FakeImages implements ImageIntrinsics {
  @override
  Size2D? intrinsicSize(String id) => null;
}

void main() {
  test('builds DrawTextOp with solid color from scene text data', () {
    final services = CoreServices(
      textMeasurer: _FakeTextMeasurer(),
      images: _FakeImages(),
    );

    const solidColor = 0xFF445566;

    final doc = CanvasSceneDocument(
      backgroundFill: const CanvasFill.none(),
      backgroundOpacity: 1.0,
      children: [
        Node.text(
          id: 't1',
          data: const TextData(
            text: 'Hello🙂',
            fontFamily: 'Inter',
            fontWeight: 400,
            fontSize: 20,
            letterSpacing: 1.25,
            appearance: CanvasAppearance(
              foreground: CanvasFill.solid(solidColor),
            ),
          ),
        ),
      ],
    );

    final computed = computeScene(doc, services);
    final ops = buildPaintOpsFromScene(doc, computed);
    final textOp = ops.whereType<DrawTextOp>().single;

    expect(textOp.text, 'Hello🙂');
    expect(textOp.letterSpacing, 1.25);
    expect(textOp.solid, solidColor);
    expect(textOp.gradient, isNull); // solid fill => no gradient shader
  });

  test('builds DrawTextOp with gradient shader when text fill is gradient', () {
    final services = CoreServices(
      textMeasurer: _FakeTextMeasurer(),
      images: _FakeImages(),
    );

    const c1 = 0xFF112233;
    const c2 = 0xFF445566;

    final doc = CanvasSceneDocument(
      backgroundFill: const CanvasFill.none(),
      backgroundOpacity: 1.0,
      children: [
        Node.text(
          id: 't1',
          data: const TextData(
            text: 'Hello',
            fontFamily: 'Inter',
            fontWeight: 400,
            fontSize: 20,
            appearance: CanvasAppearance(
              foreground: CanvasFill.gradient(
                LinearGradientSpec(color1: c1, color2: c2, angle: 0, width: 20),
              ),
            ),
          ),
        ),
      ],
    );

    final computed = computeScene(doc, services);
    final ops = buildPaintOpsFromScene(doc, computed);
    final textOp = ops.whereType<DrawTextOp>().single;

    expect(textOp.gradient, isNotNull); // ✅ gradient fill => shader exists
    expect(
      textOp.solid,
      isNull,
    ); // Foreground gradient needs no shadow fallback.
  });

  test('builds effect-only DrawTextOp without foreground', () {
    final services = CoreServices(
      textMeasurer: _FakeTextMeasurer(),
      images: _FakeImages(),
    );

    final doc = CanvasSceneDocument(
      backgroundFill: const CanvasFill.none(),
      backgroundOpacity: 1.0,
      children: [
        Node.text(
          id: 't1',
          data: const TextData(
            text: 'Hello',
            fontFamily: 'Inter',
            fontWeight: 400,
            fontSize: 20,
            appearance: CanvasAppearance(
              foreground: CanvasFill.none(),
              underlays: [
                ShadowEffect(
                  id: 'shadow',
                  offset: Vec2(20, 0),
                  color: 0x80000000,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final computed = computeScene(doc, services);
    final ops = buildPaintOpsFromScene(doc, computed);

    final textOp = ops.whereType<DrawTextOp>().single;

    expect(textOp.hasForeground, isFalse);
    expect(textOp.solid, isNull);
    expect(textOp.gradient, isNull);
    expect(textOp.underlays, hasLength(1));
    expect(textOp.underlays.single, isA<ShadowEffect>());
  });
}
