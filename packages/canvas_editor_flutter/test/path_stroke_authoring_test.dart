import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:canvas_editor_flutter/extensions.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart'
    show CanvasSceneDocumentAdapter;
import 'package:canvas_editor_flutter/src/presentation/inspector/controls.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector.dart'
    show buildSceneInspector;
import 'package:canvas_editor_flutter/src/runtime/editor_runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoText implements rt.TextMeasurer {
  @override
  rt.Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) => throw StateError('Path authoring must not measure text.');
}

class _UnusedSelection extends Fake implements EditorSelectionHost {}
class _UnusedResources extends Fake implements CanvasRuntimeResources {}

const _configured = rt.CanvasStroke(
  color: 0x00112233,
  width: 0,
  cap: rt.StrokeCap.square,
  miterLimit: 6,
  dash: [2, 0, 3],
);

rt.CanvasSceneDocument _scene({rt.CanvasStroke? stroke}) =>
    rt.CanvasSceneDocument(
      children: [
        rt.Node.path(
          id: 'path',
          name: 'Shape',
          xf: const rt.Transform2D(position: rt.Vec2(20, 30)),
          data: rt.PathData(
            source: const rt.RectSource(40, 20),
            fillRule: rt.FillRule.evenOdd,
            appearance: rt.CanvasAppearance(
              foreground: const rt.CanvasFill.solid(0xFF334455),
              stroke: stroke,
            ),
          ),
        ),
        const rt.Node.icon(id: 'icon', data: rt.CanvasIconData(iconRef: 'missing')),
      ],
    );

rt.PathNode _path(EditorRuntime<rt.CanvasSceneDocument> runtime) =>
    rt.findById(runtime.sourceDocument, 'path') as rt.PathNode;

class _Adapter extends EditorDocumentAdapter<rt.CanvasSceneDocument> {
  const _Adapter({this.resolveStroke = false, this.denyStroke = false});

  final bool resolveStroke;
  final bool denyStroke;

  @override
  rt.CanvasSceneDocument getBase(rt.CanvasSceneDocument document) => document;

  @override
  rt.CanvasSceneDocument replaceBase(
    rt.CanvasSceneDocument document,
    rt.CanvasSceneDocument base,
  ) => base;

  @override
  rt.CanvasSceneDocument resolve(rt.CanvasSceneDocument document, Object? context) {
    if (!resolveStroke) return document;
    final node = rt.findById(document, 'path') as rt.PathNode;
    return rt.replaceById(document, 'path', node.copyWith(
      data: node.data.copyWith(appearance: node.data.appearance.copyWith(
        stroke: const rt.CanvasStroke(color: 0xFFFF0000, width: 99, dash: [99]),
      )),
    ));
  }

  @override
  String? fieldEditDisabledReason(
    rt.CanvasSceneDocument document,
    rt.ElementId nodeId,
    rt.CanvasFieldKey fieldKey,
  ) => denyStroke && fieldKey == rt.CanvasFields.pathStroke
      ? 'Stroke editing is disabled'
      : null;
}

EditorRuntime<rt.CanvasSceneDocument> _runtime(
  rt.CanvasSceneDocument initial, {
  EditorDocumentAdapter<rt.CanvasSceneDocument> adapter =
      const CanvasSceneDocumentAdapter(),
}) => EditorRuntime<rt.CanvasSceneDocument>(
  initial: initial,
  adapter: adapter,
  services: rt.CoreServices(textMeasurer: _NoText()),
);

Widget _unusedFieldRow<T>(
  rt.ElementId nodeId,
  EditorController controller,
  InspectorFieldSpec<T> spec,
) => const SizedBox.shrink();

Widget _harness(EditorRuntime<rt.CanvasSceneDocument> runtime, {
  bool basePanel = false,
}) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(
    child: ValueListenableBuilder<rt.SceneEvaluation>(
      valueListenable: runtime.render,
      builder: (context, evaluation, child) {
        final inspector = InspectorContext(
          selectedId: 'path',
          selection: _UnusedSelection(),
          controller: runtime,
          editableScene: runtime.document.value,
          renderedScene: evaluation.scene,
          resources: _UnusedResources(),
          fieldRowBuilder: _unusedFieldRow,
        );
        return basePanel ? buildSceneInspector(inspector)
            : StrokeEditor(nodeId: 'path', inspector: inspector);
      },
    ),
  )),
);

Finder _number(String name) => find.descendant(
  of: find.byKey(ValueKey<String>('path:stroke-$name')),
  matching: find.byType(TextFormField),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('optional stroke commits preserve other fields and support undo and redo', () {
    final runtime = _runtime(_scene());
    addTearDown(runtime.dispose);
    final before = _path(runtime);
    final state = runtime.getField<rt.CanvasStroke?>('path', rt.CanvasFields.pathStroke);
    expect(state.value, isNull);
    expect(state.disabledReason, isNull);

    runtime.commitField<rt.CanvasStroke?>('path', rt.CanvasFields.pathStroke, null);
    expect(runtime.canUndo.value, isFalse);
    runtime.commitField<rt.CanvasStroke?>('path', rt.CanvasFields.pathStroke, _configured);
    runtime.commitField<rt.CanvasStroke?>(
      'path', rt.CanvasFields.pathStroke, _configured.copyWith(),
    );
    final after = _path(runtime);
    expect(after.data.appearance.stroke, _configured);
    expect(after.data.source, same(before.data.source));
    expect(after.data.fillRule, before.data.fillRule);
    expect(after.data.appearance.foreground, before.data.appearance.foreground);
    expect(after.xf, before.xf);
    expect(after.name, before.name);

    runtime.undo();
    expect(_path(runtime).data.appearance.stroke, isNull);
    expect(runtime.canUndo.value, isFalse);
    runtime.redo();
    runtime.commitField<rt.CanvasStroke?>('path', rt.CanvasFields.pathStroke, null);
    expect(_path(runtime).data.appearance.stroke, isNull);
    runtime.undo();
    expect(_path(runtime).data.appearance.stroke, _configured);
    runtime.redo();
    expect(_path(runtime).data.appearance.stroke, isNull);
  });

  test('stroke updates start from canonical null rather than resolved paint', () {
    final runtime = _runtime(_scene(), adapter: const _Adapter(resolveStroke: true));
    addTearDown(runtime.dispose);
    expect(runtime.getField<rt.CanvasStroke?>(
      'path', rt.CanvasFields.pathStroke,
    ).value!.width, 99);
    runtime.updateField<rt.CanvasStroke?>('path', rt.CanvasFields.pathStroke, (current) {
      expect(current, isNull);
      return _configured;
    });
    runtime.updateField<rt.CanvasStroke?>('path', rt.CanvasFields.pathStroke, (current) {
      expect(current, _configured);
      return current!.copyWith(width: 12);
    });
    expect(_path(runtime).data.appearance.stroke, _configured.copyWith(width: 12));
  });

  test('missing, wrong-kind, and denied stroke targets do not invoke updaters', () {
    final runtime = _runtime(_scene(), adapter: const _Adapter(denyStroke: true));
    addTearDown(runtime.dispose);
    final before = runtime.sourceDocument;
    var calls = 0;
    for (final id in ['missing', 'icon', 'path']) {
      runtime.commitField<rt.CanvasStroke?>(id, rt.CanvasFields.pathStroke, _configured);
      runtime.updateField<rt.CanvasStroke?>(id, rt.CanvasFields.pathStroke, (current) {
        calls++;
        return _configured;
      });
    }
    expect(calls, 0);
    expect(runtime.sourceDocument, same(before));
    expect(runtime.canUndo.value, isFalse);
  });

  testWidgets('base path inspector adds and removes strokes without stale resurrection', (tester) async {
    final runtime = _runtime(_scene());
    addTearDown(runtime.dispose);
    await tester.pumpWidget(_harness(runtime, basePanel: true));
    expect(find.byType(StrokeEditor), findsOneWidget);
    await tester.ensureVisible(find.text('Add Stroke'));
    await tester.tap(find.text('Add Stroke'));
    await tester.pump();
    expect(_path(runtime).data.appearance.stroke,
      const rt.CanvasStroke(color: 0xFF111111));
    final picker = tester.widget<SwatchPickerRow>(find.descendant(
      of: find.byType(StrokeEditor), matching: find.byType(SwatchPickerRow),
    ));
    final slider = tester.widget<LabeledSlider>(find.descendant(
      of: find.byType(StrokeEditor), matching: find.byType(LabeledSlider),
    ));
    slider.onChangeStart!(1);
    slider.onChanged!(0.5);
    await tester.pump();
    await tester.ensureVisible(find.byTooltip('Remove stroke'));
    await tester.tap(find.byTooltip('Remove stroke'));
    await tester.pump();
    expect(_path(runtime).data.appearance.stroke, isNull);
    final cleared = runtime.sourceDocument;
    picker.onPick(0xFFEF4444);
    expect(runtime.sourceDocument, same(cleared));
    runtime.undo();
    await tester.pump();
    expect(_path(runtime).data.appearance.stroke,
      const rt.CanvasStroke(color: 0x80111111));
    runtime.undo();
    await tester.pump();
    expect(_path(runtime).data.appearance.stroke,
      const rt.CanvasStroke(color: 0xFF111111));
  });

  testWidgets('stroke controls retain inactive settings and update current canonical data', (tester) async {
    final runtime = _runtime(_scene(stroke: _configured),
      adapter: const _Adapter(resolveStroke: true));
    addTearDown(runtime.dispose);
    await tester.pumpWidget(_harness(runtime));
    expect(tester.widget<TextFormField>(_number('width')).controller!.text, '0.0');
    final stalePicker = tester.widget<SwatchPickerRow>(find.byType(SwatchPickerRow));
    runtime.updateField<rt.CanvasStroke?>('path', rt.CanvasFields.pathStroke,
      (current) => current!.copyWith(dash: const [4, 0, 7]));
    stalePicker.onPick(0xFFEF4444);
    await tester.pump();
    expect(_path(runtime).data.appearance.stroke!.color, 0x00EF4444);
    expect(_path(runtime).data.appearance.stroke!.dash, [4, 0, 7]);

    await tester.enterText(_number('width'), '-1');
    await tester.pump();
    expect(find.text('Enter a finite number ≥ 0'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(_path(runtime).data.appearance.stroke!.width, 0);
    await tester.enterText(_number('width'), '12.5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(_path(runtime).data.appearance.stroke!.width, 12.5);
    await tester.enterText(_number('miter'), '0.5');
    await tester.pump();
    expect(find.text('Enter a finite number ≥ 1'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(_path(runtime).data.appearance.stroke!.miterLimit, 6);
    await tester.enterText(_number('miter'), '7.5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    final cap = tester.widget<LabeledDropdown<rt.StrokeCap>>(
      find.byType(LabeledDropdown<rt.StrokeCap>));
    cap.onChanged!(rt.StrokeCap.round);
    final join = tester.widget<LabeledDropdown<rt.StrokeJoin>>(
      find.byType(LabeledDropdown<rt.StrokeJoin>));
    join.onChanged!(rt.StrokeJoin.bevel);
    await tester.pump();
    final stroke = _path(runtime).data.appearance.stroke!;
    expect(stroke.cap, rt.StrokeCap.round);
    expect(stroke.join, rt.StrokeJoin.bevel);
    expect(stroke.miterLimit, 7.5);
    expect(stroke.width, 12.5);
    expect(stroke.dash, [4, 0, 7]);
    expect(find.text('Miter limit'), findsNothing);

    final beforeGesture = runtime.sourceDocument;
    final slider = tester.widget<LabeledSlider>(find.byType(LabeledSlider));
    slider.onChangeStart!(0);
    slider.onChanged!(0.5);
    slider.onChanged!(1);
    slider.onChangeEnd!(1);
    await tester.pump();
    expect(_path(runtime).data.appearance.stroke!.color, 0xFFEF4444);
    runtime.undo();
    await tester.pump();
    expect(runtime.sourceDocument, beforeGesture);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 0);
  });

  testWidgets('stroke policy disables inspector mutations', (tester) async {
    final runtime = _runtime(_scene(stroke: _configured),
      adapter: const _Adapter(denyStroke: true));
    addTearDown(runtime.dispose);
    await tester.pumpWidget(_harness(runtime));
    expect(find.text('Stroke editing is disabled'), findsOneWidget);
    expect(tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.delete_outline),
    ).onPressed, isNull);
    expect(tester.widget<TextFormField>(_number('width')).enabled, isFalse);
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
    expect(tester.widget<LabeledDropdown<rt.StrokeCap>>(
      find.byType(LabeledDropdown<rt.StrokeCap>)).onChanged, isNull);
  });
}
