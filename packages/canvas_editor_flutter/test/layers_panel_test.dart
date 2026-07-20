// Path: oss_packages/canvas_editor_flutter/test/layers_panel_test.dart

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
    required int letterSpacing,
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
  fill: CanvasFill.solid(0xFF111111),
  shadowOffset: 0,
);

Node _text(
  String id, {
  String? name,
  String text = 'Hello',
  bool hidden = false,
  bool locked = false,
}) {
  return Node.text(
    id: id,
    name: name,
    hidden: hidden,
    locked: locked,
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
  return defaultSceneRenderBuilder(pipeline, scene);
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

  testWidgets('locked row does not select', (tester) async {
    final controller = _RecordingEditorController(
      _scene([_text('a', name: 'Locked Layer', locked: true)]),
    );

    final selection = SelectionController();
    addTearDown(controller.dispose);
    addTearDown(selection.dispose);

    await _pumpPanel(tester, controller: controller, selection: selection);

    await _tapLayerControl(tester, find.text('Locked Layer'));

    expect(selection.value.isEmpty, isTrue);
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

  testWidgets('visibility toggle applies hidden edit', (tester) async {
    final controller = _RecordingEditorController(
      _scene([_text('a', name: 'Layer A', hidden: false)]),
    );

    final selection = SelectionController();
    addTearDown(controller.dispose);
    addTearDown(selection.dispose);

    await _pumpPanel(tester, controller: controller, selection: selection);

    await _tapLayerControl(
      tester,
      find.byIcon(Icons.visibility_outlined).first,
    );

    final node = findById(controller.document.value, 'a');

    expect(node?.hidden, true);
  });

  testWidgets('lock toggle applies locked edit', (tester) async {
    final controller = _RecordingEditorController(
      _scene([_text('a', name: 'Layer A', locked: false)]),
    );

    final selection = SelectionController();
    addTearDown(controller.dispose);
    addTearDown(selection.dispose);

    await _pumpPanel(tester, controller: controller, selection: selection);

    await _tapLayerControl(tester, find.byIcon(Icons.lock_open_outlined).first);

    final node = findById(controller.document.value, 'a');

    expect(node?.locked, true);
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
