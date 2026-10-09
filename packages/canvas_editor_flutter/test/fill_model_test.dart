// Path: oss_packages/canvas_editor_flutter/test/fill_model_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/canvas_runtime_resources.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart'
    show CanvasSceneDocumentAdapter, EditorController, kSceneFieldsId;
import 'package:canvas_editor_flutter/src/editor_fill.dart';
import 'package:canvas_editor_flutter/src/editor_hosts.dart'
    show EditorSelectionHost;
import 'package:canvas_editor_flutter/src/presentation/inspector/fill_editor.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_context.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_field_row.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_fields.dart';
import 'package:canvas_editor_flutter/src/runtime/editor_runtime.dart';
import 'package:flutter/material.dart';
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

class _UnusedSelection extends Fake implements EditorSelectionHost {}

class _UnusedResources extends Fake implements CanvasRuntimeResources {}

Widget _buildFieldRow<T>(
  ElementId nodeId,
  EditorController controller,
  InspectorFieldSpec<T> spec,
) => InspectorFieldRow<T>(nodeId: nodeId, controller: controller, spec: spec);

void main() {
  final gradient = CanvasFill.gradient(
    LinearGradientSpec(
      start: const Vec2(-10, 0),
      end: const Vec2(10, 0),
      stops: const <GradientStop>[
        GradientStop(offset: 0, color: 0xFF224466),
        GradientStop(offset: 1, color: 0xFFAACCEE),
      ],
    ),
  );

  final targets = [
    (
      name: 'text',
      id: 't1',
      field: CanvasFields.textFill,
      nodes: <Node>[
        const Node.text(
          id: 't1',
          data: TextData(
            text: 'Hello',
            fontFamily: 'Inter',
            fontWeight: 400,
            fontSize: 24,
            letterSpacing: 0,
            appearance: CanvasAppearance(
              foreground: CanvasFill.solid(0xFF010203),
            ),
          ),
        ),
      ],
    ),
    (
      name: 'icon',
      id: 'i1',
      field: CanvasFields.iconFill,
      nodes: <Node>[
        const Node.icon(
          id: 'i1',
          data: CanvasIconData(
            iconRef: 'star',
            sizePx: 48,
            appearance: CanvasAppearance(
              foreground: CanvasFill.solid(0xFF010203),
            ),
          ),
        ),
      ],
    ),
    (
      name: 'path',
      id: 'p1',
      field: CanvasFields.pathFill,
      nodes: <Node>[
        const Node.path(
          id: 'p1',
          data: PathData(fill: CanvasFill.solid(0xFF010203)),
        ),
      ],
    ),
    (
      name: 'background',
      id: kSceneFieldsId,
      field: CanvasFields.sceneBackgroundFill,
      nodes: <Node>[],
    ),
  ];

  for (final target in targets) {
    for (final fill in <CanvasFill>[
      const CanvasFill.none(),
      const CanvasFill.solid(0xFFABCDEF),
      gradient,
    ]) {
      test('${target.name} accepts ${fillVariantOf(fill).name} and undoes', () {
        final initial = _sceneWithChildren(
          target.nodes,
        ).copyWith(backgroundFill: const CanvasFill.solid(0xFF010203));
        final runtime = _buildRuntime(initial);
        addTearDown(runtime.dispose);

        runtime.commitField<CanvasFill>(target.id, target.field, fill);

        expect(
          runtime.getField<CanvasFill>(target.id, target.field).value,
          fill,
        );
        expect(runtime.canUndo.value, isTrue);

        runtime.undo();
        expect(runtime.sourceDocument.toJson(), initial.toJson());

        runtime.redo();
        expect(
          runtime.getField<CanvasFill>(target.id, target.field).value,
          fill,
        );
      });
    }
  }

  test('wrong-kind and unchanged fill edits do not add undo entries', () {
    final initial = _sceneWithChildren([
      const Node.path(
        id: 'p1',
        data: PathData(fill: CanvasFill.solid(0xFF010203)),
      ),
    ]);
    final runtime = _buildRuntime(initial);
    addTearDown(runtime.dispose);

    runtime.commitField<CanvasFill>('p1', CanvasFields.textFill, gradient);
    runtime.commitField<CanvasFill>('missing', CanvasFields.pathFill, gradient);
    runtime.commitField<CanvasFill>(
      'p1',
      CanvasFields.pathFill,
      const CanvasFill.solid(0xFF010203),
    );

    expect(runtime.sourceDocument.toJson(), initial.toJson());
    expect(runtime.canUndo.value, isFalse);
  });

  test('representative fill colors keep target fallbacks and RGB', () {
    expect(FillFieldIds.text.fallbackColor, 0xFF111111);
    expect(FillFieldIds.icon.fallbackColor, 0xFF111111);
    expect(FillFieldIds.path.fallbackColor, 0xFF000000);
    expect(FillFieldIds.background.fallbackColor, 0xFF000000);

    for (final fallback in <int>[0xFF111111, 0xFF000000]) {
      expect(
        representativeColorForFill(const CanvasFill.none(), fallback),
        fallback,
      );
      expect(
        representativeColorForFill(
          const CanvasFill.solid(0x00000000),
          fallback,
        ),
        fallback,
      );
      expect(
        representativeColorForFill(
          const CanvasFill.solid(0x00123456),
          fallback,
        ),
        0xFF123456,
      );
    }
    expect(representativeColorForFill(gradient, 0xFF000000), 0xFF224466);
  });

  test('default gradient requires finite, positive-width local bounds', () {
    expect(
      () => createDefaultGradient(
        referenceBounds: const Rect2D(0, 0, 0, 30),
        color: 0xFF000000,
      ),
      throwsArgumentError,
    );
    expect(
      () => createDefaultGradient(
        referenceBounds: const Rect2D(double.nan, 0, 30, 30),
        color: 0xFF000000,
      ),
      throwsArgumentError,
    );
  });

  testWidgets('gradient creation is disabled without usable bounds', (
    tester,
  ) async {
    final initial = _sceneWithChildren(const <Node>[]);
    final runtime = _buildRuntime(initial);
    addTearDown(runtime.dispose);

    Future<void> showFillEditor(CanvasSceneDocument editable) async {
      final inspector = InspectorContext(
        selectedId: null,
        selection: _UnusedSelection(),
        controller: runtime,
        editableScene: editable,
        renderedScene: runtime.render.value.scene,
        resources: _UnusedResources(),
        fieldRowBuilder: _buildFieldRow,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FillEditor(
              nodeId: kSceneFieldsId,
              inspector: inspector,
              ids: FillFieldIds.background,
              header: null,
            ),
          ),
        ),
      );
    }

    // Only the inspector's editable bounds are unavailable. The live
    // controller/render remains a valid scene.
    await showFillEditor(initial.copyWith(artboardSize: const Size2D(0, 200)));
    final dropdownFinder = find.byType(DropdownButtonFormField<FillVariant>);
    final unavailable = tester.widget<DropdownButtonFormField<FillVariant>>(
      dropdownFinder,
    );
    expect(
      unavailable.items!.map((item) => item.value).toList(),
      FillVariant.values,
    );
    expect(
      unavailable.items!
          .singleWhere((item) => item.value == FillVariant.gradient)
          .enabled,
      isFalse,
    );

    await showFillEditor(initial);
    final available = tester.widget<DropdownButtonFormField<FillVariant>>(
      dropdownFinder,
    );
    expect(
      available.items!
          .singleWhere((item) => item.value == FillVariant.gradient)
          .enabled,
      isTrue,
    );
  });

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
        0xFF000000,
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
