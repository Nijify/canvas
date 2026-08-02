// Path: oss_packages/canvas_editor_flutter/test/fill_model_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart'
    show CanvasSceneDocumentAdapter, kSceneFieldsId;
import 'package:canvas_editor_flutter/src/editor_fill.dart';
import 'package:canvas_editor_flutter/src/runtime/editor_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTextMeasurer implements TextMeasurer {
  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) {
    return Size2D(text.length * fontSize * 0.6, fontSize);
  }
}

CanvasSceneDocument _sceneWithChildren(List<Node> children) {
  return CanvasSceneDocument(
    artboardSize: const Size2D(300, 200),
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: children,
  );
}

EditorRuntime<CanvasSceneDocument> _buildRuntime(CanvasSceneDocument scene) {
  return EditorRuntime<CanvasSceneDocument>(
    initial: scene,
    adapter: const CanvasSceneDocumentAdapter(),
    renderPipeline: CanvasRenderPipeline(textMeasurer: _FakeTextMeasurer()),
    imageIntrinsics: null,
  );
}

void main() {
  test('path can be set to none', () {
    final runtime = _buildRuntime(
      _sceneWithChildren([
        const Node.path(
          id: 'p1',
          data: PathData(fill: CanvasFill.solid(0xFF000000)),
        ),
      ]),
    );
    addTearDown(runtime.dispose);

    runtime.commitField<CanvasFill>(
      'p1',
      CanvasFields.pathFill,
      const CanvasFill.none(),
    );

    final node = findById(runtime.sourceDocument, 'p1') as PathNode;
    expect(node.data.fill, const CanvasFill.none());
  });

  test('text fill cannot be none and is coerced to fallback', () {
    final runtime = _buildRuntime(
      _sceneWithChildren([
        const Node.text(
          id: 't1',
          data: TextData(
            text: 'Hello',
            fontFamily: 'Inter',
            fontWeight: 700,
            fontSize: 24,
            letterSpacing: 0,
            fill: CanvasFill.solid(0xFF123456),
            shadowOffset: 0,
          ),
        ),
      ]),
    );
    addTearDown(runtime.dispose);

    runtime.commitField<CanvasFill>(
      't1',
      CanvasFields.textFill,
      const CanvasFill.none(),
    );

    final node = findById(runtime.sourceDocument, 't1') as TextNode;
    expect(node.data.fill, const CanvasFill.solid(0xFF111111));
  });

  test('icon fill cannot be none and is coerced to fallback', () {
    final runtime = _buildRuntime(
      _sceneWithChildren([
        const Node.icon(
          id: 'i1',
          data: CanvasIconData(
            iconRef: 'star',
            sizePx: 48,
            fill: CanvasFill.solid(0xFF123456),
            shadowOffset: 0,
          ),
        ),
      ]),
    );
    addTearDown(runtime.dispose);

    runtime.commitField<CanvasFill>(
      'i1',
      CanvasFields.iconFill,
      const CanvasFill.none(),
    );

    final node = findById(runtime.sourceDocument, 'i1') as IconNode;
    expect(node.data.fill, const CanvasFill.solid(0xFF111111));
  });

  test('solid to gradient conversion preserves representative color', () {
    final next = convertFillVariant(
      const CanvasFill.solid(0xFFABCDEF),
      FillVariant.gradient,
      kPathFillCapability,
    );

    expect(next, isA<CanvasFillGradient>());

    final gradient = (next as CanvasFillGradient).grad;
    expect(gradient.color1, 0xFFABCDEF);
    expect(gradient.color2, 0xFFABCDEF);
  });

  test('gradient to solid conversion uses color1', () {
    final next = convertFillVariant(
      const CanvasFill.gradient(
        LinearGradientSpec(
          color1: 0xFF111111,
          color2: 0xFFFFFFFF,
          angle: 45,
          width: 20,
        ),
      ),
      FillVariant.solid,
      kPathFillCapability,
    );

    expect(next, const CanvasFill.solid(0xFF111111));
  });

  test('patchLinearGradient preserves geometry when editing one color', () {
    final next = patchLinearGradient(
      const CanvasFill.gradient(
        LinearGradientSpec(
          color1: 0xFF111111,
          color2: 0xFFFFFFFF,
          angle: 45,
          width: 30,
        ),
      ),
      const LinearGradientPatch(color1: 0xFF22C55E),
      kPathFillCapability,
    );

    final gradient = (next as CanvasFillGradient).grad;
    expect(gradient.color1, 0xFF22C55E);
    expect(gradient.color2, 0xFFFFFFFF);
    expect(gradient.angle, 45);
    expect(gradient.width, 30);
  });

  test('patchLinearGradient preserves colors when editing geometry', () {
    final next = patchLinearGradient(
      const CanvasFill.gradient(
        LinearGradientSpec(
          color1: 0xFF111111,
          color2: 0xFFFFFFFF,
          angle: 45,
          width: 30,
        ),
      ),
      const LinearGradientPatch(angle: 135, width: 12),
      kPathFillCapability,
    );

    final gradient = (next as CanvasFillGradient).grad;
    expect(gradient.color1, 0xFF111111);
    expect(gradient.color2, 0xFFFFFFFF);
    expect(gradient.angle, 135);
    expect(gradient.width, 12);
  });

  test(
    'representativeColorForFill restores alpha for transparent RGB color',
    () {
      final color = representativeColorForFill(
        const CanvasFill.solid(0x00123456),
        kPathFillCapability,
      );

      expect(color, 0xFF123456);
    },
  );

  test('background fill and opacity are editable and undoable', () {
    final runtime = _buildRuntime(_sceneWithChildren(const <Node>[]));
    addTearDown(runtime.dispose);

    const fill = CanvasFill.gradient(
      LinearGradientSpec(
        color1: 0xFF2563EB,
        color2: 0xFF06B6D4,
        angle: 45,
        width: 20,
      ),
    );

    runtime.commitField<CanvasFill>(
      kSceneFieldsId,
      CanvasFields.sceneBackgroundFill,
      fill,
    );

    expect(runtime.sourceDocument.backgroundFill, fill);
    expect(runtime.sourceDocument.backgroundOpacity, 1.0);

    runtime.commitField<double>(
      kSceneFieldsId,
      CanvasFields.sceneBackgroundOpacity,
      0.4,
    );

    expect(runtime.sourceDocument.backgroundFill, fill);
    expect(runtime.sourceDocument.backgroundOpacity, 0.4);

    runtime.undo();

    expect(runtime.sourceDocument.backgroundFill, fill);
    expect(runtime.sourceDocument.backgroundOpacity, 1.0);

    runtime.undo();

    expect(runtime.sourceDocument.backgroundFill, const CanvasFill.none());
    expect(runtime.sourceDocument.backgroundOpacity, 1.0);

    runtime.redo();
    runtime.redo();

    expect(runtime.sourceDocument.backgroundFill, fill);
    expect(runtime.sourceDocument.backgroundOpacity, 0.4);
  });
}
