// Path: oss_packages/canvas_editor_flutter/test/editor_action_context_scene_boundary_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart';
import 'package:canvas_editor_flutter/src/canvas_runtime_resources.dart';
import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart';
import 'package:canvas_editor_flutter/src/presentation/actions/editor_actions.dart';
import 'package:flutter/foundation.dart';
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

class _NoopUiFeedback implements UiFeedback {
  @override
  void hideSpinner() {}

  @override
  void showSpinner() {}

  @override
  void toast(String msg) {}
}

class _FakeEditorController implements EditorController {
  _FakeEditorController({
    required RenderSnapshot renderSnapshot,
    required CanvasSceneDocument document,
  }) : _render = ValueNotifier<RenderSnapshot>(renderSnapshot),
       _document = ValueNotifier<CanvasSceneDocument>(document);

  final ValueNotifier<RenderSnapshot> _render;
  final ValueNotifier<CanvasSceneDocument> _document;
  final ValueNotifier<bool> _canUndo = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _canRedo = ValueNotifier<bool>(false);

  @override
  ValueListenable<RenderSnapshot> get render => _render;

  @override
  ValueListenable<CanvasSceneDocument> get document => _document;

  @override
  ValueListenable<bool> get canUndo => _canUndo;

  @override
  ValueListenable<bool> get canRedo => _canRedo;

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

RenderSnapshot _snapshotFor(CanvasSceneDocument scene) {
  final pipeline = CanvasRenderPipeline(textMeasurer: _FakeTextMeasurer());
  return pipeline.build(scene);
}

CanvasSceneDocument _scene(double backgroundOpacity) {
  return CanvasSceneDocument(
    artboardSize: const Size2D(300, 200),
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: backgroundOpacity,
    children: const <Node>[],
  );
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
  testWidgets(
    'EditorActionContext exposes editableScene and renderScene separately',
    (tester) async {
      final editableScene = _scene(0.1);
      final renderScene = _scene(0.9);

      final controller = _FakeEditorController(
        renderSnapshot: _snapshotFor(renderScene),
        document: editableScene,
      );

      final selection = SelectionController();

      addTearDown(selection.dispose);
      addTearDown(controller.dispose);

      final context = await _pumpContext(tester);

      final actionContext = EditorActionContext(
        buildContext: context,
        resources: _resources(),
        ui: _NoopUiFeedback(),
        controller: controller,
        selection: selection,
      );

      expect(actionContext.editableScene.backgroundOpacity, 0.1);
      expect(actionContext.renderScene.backgroundOpacity, 0.9);
    },
  );
}
