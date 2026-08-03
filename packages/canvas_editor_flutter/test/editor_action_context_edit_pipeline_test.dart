// Path: oss_packages/canvas_editor_flutter/test/editor_action_context_edit_pipeline_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart';
import 'package:canvas_editor_flutter/src/canvas_runtime_resources.dart';
import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart';
import 'package:canvas_editor_flutter/src/presentation/actions/editor_actions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoopUiFeedback implements UiFeedback {
  @override
  void hideSpinner() {}

  @override
  void showSpinner() {}

  @override
  void toast(String msg) {}
}

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

class _FakeEditorController implements EditorController {
  _FakeEditorController(CanvasSceneDocument scene)
    : _scene = scene,
      _render = ValueNotifier<RenderSnapshot>(_snapshotFor(scene)),
      _document = ValueNotifier<CanvasSceneDocument>(scene);

  CanvasSceneDocument _scene;

  final ValueNotifier<RenderSnapshot> _render;
  final ValueNotifier<CanvasSceneDocument> _document;
  final ValueNotifier<bool> _canUndo = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _canRedo = ValueNotifier<bool>(false);

  EditorEdit? lastEdit;

  @override
  ValueListenable<RenderSnapshot> get render => _render;

  @override
  ValueListenable<CanvasSceneDocument> get document => _document;

  @override
  ValueListenable<bool> get canUndo => _canUndo;

  @override
  ValueListenable<bool> get canRedo => _canRedo;

  @override
  ElementId? applyEdit(EditorEdit edit) {
    lastEdit = edit;

    final result = edit(_scene);
    _scene = result.scene;

    _document.value = _scene;
    _render.value = _snapshotFor(_scene);

    return result.primaryId;
  }

  @override
  void dispose() {
    _render.dispose();
    _document.dispose();
    _canUndo.dispose();
    _canRedo.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMediaResolver implements CanvasMediaResolver {
  @override
  Future<String?> resolveUrl(String assetId) async => null;

  @override
  Future<Map<String, String>> resolveUrls(List<String> assetIds) async =>
      const <String, String>{};

  @override
  Future<Size2D?> resolveIntrinsicSize(String refOrId) async => null;

  @override
  Future<Map<String, Size2D>> resolveIntrinsicSizes(
    List<String> refsOrIds,
  ) async => const <String, Size2D>{};
}

class _FakeFontAssets implements CanvasFontAssets {
  @override
  List<FontDef> get pickerFonts => const <FontDef>[];

  @override
  List<FontDef> get loadableFonts => const <FontDef>[];

  @override
  Iterable<String> get fallbackFontFamilies => const <String>[];

  @override
  Future<void> ensureLoaded(Iterable<String> families) async {}
}

class _FakeIconCatalogPort implements IconCatalogPort {
  @override
  List<IconCatalogItem> get items => const <IconCatalogItem>[];

  @override
  Map<String, ResolvedIcon> get resolveMap => const <String, ResolvedIcon>{};

  @override
  ResolvedIcon? resolve(String iconRef) => null;
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

CanvasSceneDocument _sceneWithChildren(List<Node> children) {
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

CanvasRuntimeResources _resources() {
  return CanvasRuntimeResources(
    fonts: _FakeFontAssets(),
    icons: _FakeIconCatalogPort(),
    media: _FakeMediaResolver(),
  );
}

Future<BuildContext> _pumpContext(WidgetTester tester) async {
  late BuildContext captured;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  return captured;
}

void main() {
  testWidgets('addNodeAndSelect applies edit and selects created node', (
    tester,
  ) async {
    final controller = _FakeEditorController(
      _sceneWithChildren(const <Node>[]),
    );
    final selection = SelectionController();

    addTearDown(controller.dispose);
    addTearDown(selection.dispose);

    final ctx = EditorActionContext(
      buildContext: await _pumpContext(tester),
      resources: _resources(),
      ui: _NoopUiFeedback(),
      controller: controller,
      selection: selection,
    );

    final id = ctx.addNodeAndSelect(const Node.text(id: 't1', data: _textData));

    expect(id, 't1');
    expect(selection.firstId, 't1');
    expect(controller.document.value.children.single.id, 't1');
  });

  testWidgets('duplicateSelection applies edit and selects duplicate', (
    tester,
  ) async {
    final controller = _FakeEditorController(
      _sceneWithChildren(const [Node.text(id: 't1', data: _textData)]),
    );
    final selection = SelectionController()..selectItems(const <String>['t1']);

    addTearDown(controller.dispose);
    addTearDown(selection.dispose);

    final ctx = EditorActionContext(
      buildContext: await _pumpContext(tester),
      resources: _resources(),
      ui: _NoopUiFeedback(),
      controller: controller,
      selection: selection,
    );

    ctx.duplicateSelection();

    expect(controller.document.value.children, hasLength(2));
    expect(selection.firstId, isNot('t1'));
    expect(selection.firstId, isNotNull);
  });

  testWidgets('deleteSelection applies edit and clears selection', (
    tester,
  ) async {
    final controller = _FakeEditorController(
      _sceneWithChildren(const [Node.text(id: 't1', data: _textData)]),
    );
    final selection = SelectionController()..selectItems(const <String>['t1']);

    addTearDown(controller.dispose);
    addTearDown(selection.dispose);

    final ctx = EditorActionContext(
      buildContext: await _pumpContext(tester),
      resources: _resources(),
      ui: _NoopUiFeedback(),
      controller: controller,
      selection: selection,
    );

    ctx.deleteSelection();

    expect(controller.document.value.children, isEmpty);
    expect(selection.value.isEmpty, isTrue);
  });
}
