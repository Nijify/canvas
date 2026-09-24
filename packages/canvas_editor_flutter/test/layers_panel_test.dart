// Path: packages/canvas_editor_flutter/test/layers_panel_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart';
import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart';
import 'package:canvas_editor_flutter/src/presentation/layers/scene_object_tree.dart';
import 'package:canvas_editor_flutter/src/presentation/layers/layers_panel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
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

const _textData = TextData(
  text: 'Hello',
  fontFamily: 'Inter',
  fontWeight: 700,
  fontSize: 24,
  letterSpacing: 0,
  appearance: CanvasAppearance(foreground: CanvasFill.solid(0xFF111111)),
);

Node _text(
  String id, {
  String? name,
  String text = 'Hello',
  bool hidden = false,
}) {
  return Node.text(
    id: id,
    name: name,
    hidden: hidden,
    data: _textData.copyWith(text: text),
  );
}

CanvasSceneDocument _scene(List<Node> children) {
  return CanvasSceneDocument(
    artboardSize: const Size2D(300, 200),
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: children,
  );
}

RenderSnapshot _snapshotFor(CanvasSceneDocument scene) {
  final pipeline = CanvasRenderPipeline(textMeasurer: _FakeTextMeasurer());
  return pipeline.build(scene);
}

class _RecordingEditorController implements EditorController {
  _RecordingEditorController(CanvasSceneDocument scene)
    : _document = ValueNotifier<CanvasSceneDocument>(scene),
      _render = ValueNotifier<RenderSnapshot>(_snapshotFor(scene));

  final ValueNotifier<CanvasSceneDocument> _document;
  final ValueNotifier<RenderSnapshot> _render;
  final ValueNotifier<bool> _canUndo = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _canRedo = ValueNotifier<bool>(false);

  final appliedEdits = <EditorEdit>[];

  @override
  ValueListenable<CanvasSceneDocument> get document => _document;

  @override
  ValueListenable<RenderSnapshot> get render => _render;

  @override
  ValueListenable<bool> get canUndo => _canUndo;

  @override
  ValueListenable<bool> get canRedo => _canRedo;

  @override
  ElementId? applyEdit(EditorEdit edit) {
    appliedEdits.add(edit);

    final result = edit(_document.value);

    _document.value = result.scene;
    _render.value = _snapshotFor(result.scene);

    return result.primaryId;
  }

  @override
  void dispose() {
    _document.dispose();
    _render.dispose();
    _canUndo.dispose();
    _canRedo.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LabelPolicy extends SceneObjectPresentationPolicy {
  const _LabelPolicy();

  @override
  String labelForNode(CanvasSceneDocument scene, Node node) {
    if (node.id == 'component') return 'Component Label';
    return super.labelForNode(scene, node);
  }
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required _RecordingEditorController controller,
  required SelectionController selection,
  SceneObjectPresentationPolicy policy = const SceneObjectPresentationPolicy(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          height: 500,
          child: LayersPanel(
            controller: controller,
            selection: selection,
            policy: policy,
          ),
        ),
      ),
    ),
  );
}

Future<void> _tapLayerControl(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump(kDoubleTapTimeout);
  await tester.pump();
}

void main() {
  testWidgets('renders rows from editable scene in front-to-back order', (
    tester,
  ) async {
    final controller = _RecordingEditorController(
      _scene([_text('back', name: 'Back'), _text('front', name: 'Front')]),
    );

    final selection = SelectionController();
    addTearDown(controller.dispose);
    addTearDown(selection.dispose);

    await _pumpPanel(tester, controller: controller, selection: selection);

    expect(find.text('Layers'), findsOneWidget);
    expect(find.text('Front'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    final frontTop = tester.getTopLeft(find.text('Front')).dy;
    final backTop = tester.getTopLeft(find.text('Back')).dy;

    expect(frontTop, lessThan(backTop));
  });

  testWidgets('shows fallback labels when node has no explicit name', (
    tester,
  ) async {
    final controller = _RecordingEditorController(
      _scene([_text('title', text: 'Welcome')]),
    );

    final selection = SelectionController();
    addTearDown(controller.dispose);
    addTearDown(selection.dispose);

    await _pumpPanel(tester, controller: controller, selection: selection);

    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('tap row updates SelectionController', (tester) async {
    final controller = _RecordingEditorController(
      _scene([_text('a', name: 'Layer A')]),
    );

    final selection = SelectionController();
    addTearDown(controller.dispose);
    addTearDown(selection.dispose);

    await _pumpPanel(tester, controller: controller, selection: selection);

    await _tapLayerControl(tester, find.text('Layer A'));

    expect(selection.value.hasItems, isTrue);
    expect(selection.value.ids, const <String>{'a'});
  });

  testWidgets('rename dialog applies rename edit with row id', (tester) async {
    final controller = _RecordingEditorController(
      _scene([_text('a', name: 'Old Name')]),
    );

    final selection = SelectionController();
    addTearDown(controller.dispose);
    addTearDown(selection.dispose);

    await _pumpPanel(tester, controller: controller, selection: selection);

    await _tapLayerControl(
      tester,
      find.byIcon(Icons.drive_file_rename_outline).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Rename layer'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'New Name');
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    final node = findById(controller.document.value, 'a');

    expect(node?.name, 'New Name');
  });

  testWidgets(
    'hidden node remains selectable and renameable without visibility controls',
    (tester) async {
      final controller = _RecordingEditorController(
        _scene([_text('a', name: 'Hidden Layer', hidden: true)]),
      );

      final selection = SelectionController();
      addTearDown(controller.dispose);
      addTearDown(selection.dispose);

      await _pumpPanel(tester, controller: controller, selection: selection);

      // Persisted hidden nodes still belong to the canonical object tree.
      expect(find.text('Hidden Layer'), findsOneWidget);

      // Layers no longer exposes generic visibility controls.
      expect(find.byTooltip('Show layer'), findsNothing);
      expect(find.byTooltip('Hide layer'), findsNothing);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      // Hidden nodes remain selectable from Layers.
      await _tapLayerControl(tester, find.text('Hidden Layer'));

      expect(selection.value.hasItems, isTrue);
      expect(selection.value.ids, const <String>{'a'});

      // Hidden nodes also remain renameable from Layers.
      await _tapLayerControl(
        tester,
        find.byIcon(Icons.drive_file_rename_outline).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Rename layer'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Renamed Hidden Layer');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      final node = findById(controller.document.value, 'a');

      expect(node?.name, 'Renamed Hidden Layer');
      expect(node?.hidden, true);
    },
  );

  testWidgets('does not render canvas-object lock controls', (tester) async {
    final controller = _RecordingEditorController(
      _scene([_text('a', name: 'Layer A')]),
    );

    final selection = SelectionController();
    addTearDown(controller.dispose);
    addTearDown(selection.dispose);

    await _pumpPanel(tester, controller: controller, selection: selection);

    expect(find.byTooltip('Lock layer'), findsNothing);
    expect(find.byTooltip('Unlock layer'), findsNothing);
  });

  testWidgets('uses provided scene object policy', (tester) async {
    final controller = _RecordingEditorController(
      _scene([Node.group(id: 'component', children: const <Node>[])]),
    );

    final selection = SelectionController();
    addTearDown(controller.dispose);
    addTearDown(selection.dispose);

    await _pumpPanel(
      tester,
      controller: controller,
      selection: selection,
      policy: const _LabelPolicy(),
    );

    expect(find.text('Component Label'), findsOneWidget);
  });

  testWidgets('empty scene shows empty state', (tester) async {
    final controller = _RecordingEditorController(_scene(const <Node>[]));

    final selection = SelectionController();
    addTearDown(controller.dispose);
    addTearDown(selection.dispose);

    await _pumpPanel(tester, controller: controller, selection: selection);

    expect(find.text('No layers yet'), findsOneWidget);
  });
}
