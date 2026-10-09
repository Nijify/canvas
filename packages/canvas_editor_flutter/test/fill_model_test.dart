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
    services: CoreServices(textMeasurer: _FakeTextMeasurer()),
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

  test('text foreground can be set to none', () {
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
            appearance: CanvasAppearance(
              foreground: CanvasFill.solid(0xFF123456),
            ),
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

    expect(node.data.appearance.foreground, const CanvasFill.none());
  });

  test('icon foreground can be set to none', () {
    final runtime = _buildRuntime(
      _sceneWithChildren([
        const Node.icon(
          id: 'i1',
          data: CanvasIconData(
            iconRef: 'star',
            sizePx: 48,
            appearance: CanvasAppearance(
              foreground: CanvasFill.solid(0xFF123456),
            ),
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

    expect(node.data.appearance.foreground, const CanvasFill.none());
  });

  test('creates a horizontal default gradient from local bounds', () {
    final gradient = createDefaultGradient(
      referenceBounds: const Rect2D(-20, 10, 80, 50),
      color: 0xFFABCDEF,
    );

    expect(gradient.start, const Vec2(-20, 30));
    expect(gradient.end, const Vec2(80, 30));
    expect(gradient.stops, const <GradientStop>[
      GradientStop(offset: 0, color: 0xFFABCDEF),
      GradientStop(offset: 1, color: 0xFFABCDEF),
    ]);
  });

  test('gradient to solid coercion uses the first stop color', () {
    final gradient = CanvasFill.gradient(
      LinearGradientSpec(
        start: const Vec2(-10, 0),
        end: const Vec2(10, 0),
        stops: const <GradientStop>[
          GradientStop(offset: 0, color: 0xFF111111),
          GradientStop(offset: 1, color: 0xFFFFFFFF),
        ],
      ),
    );

    final next = coerceFill(
      gradient,
      const FillCapability(
        allowed: <FillVariant>{FillVariant.solid},
        fallback: CanvasFill.solid(0xFF000000),
      ),
    );

    expect(next, const CanvasFill.solid(0xFF111111));
  });

  test('replacing a stop color preserves endpoints and interior stops', () {
    final gradient = LinearGradientSpec(
      start: const Vec2(-20, 5),
      end: const Vec2(20, 5),
      stops: const <GradientStop>[
        GradientStop(offset: 0, color: 0xFF111111),
        GradientStop(offset: 0.5, color: 0xFFAAAAAA),
        GradientStop(offset: 1, color: 0xFFFFFFFF),
      ],
    );

    final next = replaceGradientStopColor(
      gradient,
      index: 2,
      color: 0xFF22C55E,
    );

    expect(next.start, gradient.start);
    expect(next.end, gradient.end);
    expect(next.stops, const <GradientStop>[
      GradientStop(offset: 0, color: 0xFF111111),
      GradientStop(offset: 0.5, color: 0xFFAAAAAA),
      GradientStop(offset: 1, color: 0xFF22C55E),
    ]);
  });

  test('angle editing preserves midpoint, length, and stops', () {
    final gradient = LinearGradientSpec(
      start: const Vec2(-20, 5),
      end: const Vec2(20, 5),
      stops: const <GradientStop>[
        GradientStop(offset: 0, color: 0xFF111111),
        GradientStop(offset: 1, color: 0xFFFFFFFF),
      ],
    );

    final next = setLinearGradientAngleDegrees(gradient, 90);

    expect(linearGradientAngleDegrees(next), closeTo(90, 1e-9));
    expect((next.start + next.end) / 2.0, const Vec2(0, 5));
    expect((next.end - next.start).length, closeTo(40, 1e-9));
    expect(next.stops, gradient.stops);
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

    final fill = CanvasFill.gradient(
      LinearGradientSpec(
        start: const Vec2(0, 0),
        end: const Vec2(300, 0),
        stops: const <GradientStop>[
          GradientStop(offset: 0, color: 0xFF2563EB),
          GradientStop(offset: 1, color: 0xFF06B6D4),
        ],
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
