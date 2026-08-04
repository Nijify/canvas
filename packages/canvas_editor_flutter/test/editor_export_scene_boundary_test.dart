// Path: oss_packages/canvas_editor_flutter/test/editor_export_scene_boundary_test.dart

import 'dart:convert';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart';
import 'package:canvas_editor_flutter/src/editor_host_capabilities.dart';
import 'package:canvas_editor_flutter/src/canvas_runtime_resources.dart';
import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart';
import 'package:canvas_editor_flutter/src/presentation/actions/editor_action_sets.dart';
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

class _RecordingJsonOutputPort extends JsonOutputPort {
  String? copiedJson;
  String? savedJson;

  @override
  Future<String> copyJson({required String json}) async {
    copiedJson = json;
    return 'copied';
  }

  @override
  Future<String> saveJson({
    required String json,
    required String filename,
  }) async {
    savedJson = json;
    return 'saved';
  }
}

class _RecordingEditorExports implements EditorExports {
  CanvasSceneDocument? preparedScene;
  EditorExportSpec? spec;

  @override
  Future<Uint8List> renderPng({
    required CanvasSceneDocument preparedScene,
    required EditorExportSpec spec,
  }) async {
    this.preparedScene = preparedScene;
    this.spec = spec;
    return Uint8List.fromList(const [1, 2, 3]);
  }
}

class _RecordingPngOutputPort extends PngOutputPort {
  Uint8List? sharedBytes;
  Uint8List? savedBytes;

  @override
  Future<String> sharePng(
    Uint8List bytes, {
    required String filename,
    String? text,
  }) async {
    sharedBytes = bytes;
    return 'shared';
  }

  @override
  Future<String> savePng(Uint8List bytes, {required String filename}) async {
    savedBytes = bytes;
    return 'saved';
  }
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

EditorActionContext _actionContext({
  required BuildContext context,
  required _FakeEditorController controller,
  required SelectionController selection,
}) {
  return EditorActionContext(
    buildContext: context,
    resources: _resources(),
    ui: _NoopUiFeedback(),
    controller: controller,
    selection: selection,
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
  testWidgets('Scene JSON export uses editable/base scene', (tester) async {
    final editableScene = _scene(0.1);
    final renderScene = _scene(0.9);

    final output = _RecordingJsonOutputPort();

    final actions = sceneJsonExportActions(
      JsonExportCapability(output: output, pretty: false),
    );

    final copyAction = actions.singleWhere(
      (action) => action.id == EditorActionIds.copySceneJson,
    );

    final context = await _pumpContext(tester);

    final controller = _FakeEditorController(
      renderSnapshot: _snapshotFor(renderScene),
      document: editableScene,
    );

    final selection = SelectionController();

    addTearDown(selection.dispose);
    addTearDown(controller.dispose);

    final ctx = _actionContext(
      context: context,
      controller: controller,
      selection: selection,
    );

    await copyAction.invoke(ctx);

    final decoded = jsonDecode(output.copiedJson!) as Map<String, dynamic>;

    expect(decoded['backgroundOpacity'], 0.1);
  });

  testWidgets('PNG export uses render/prepared scene', (tester) async {
    final editableScene = _scene(0.1);
    final renderScene = _scene(0.9);

    final renderer = _RecordingEditorExports();
    final output = _RecordingPngOutputPort();

    final actions = pngExportActions(
      PngExportCapability(renderer: renderer, output: output),
    );

    final shareAction = actions.singleWhere(
      (action) => action.id == EditorActionIds.sharePng,
    );

    final context = await _pumpContext(tester);

    final controller = _FakeEditorController(
      renderSnapshot: _snapshotFor(renderScene),
      document: editableScene,
    );

    final selection = SelectionController();

    addTearDown(selection.dispose);
    addTearDown(controller.dispose);

    final ctx = _actionContext(
      context: context,
      controller: controller,
      selection: selection,
    );

    await shareAction.invoke(ctx);

    expect(identical(renderer.preparedScene, renderScene), isTrue);
    expect(renderer.preparedScene?.backgroundOpacity, 0.9);
    expect(renderer.spec?.fit, CanvasFit.contain);
    expect(output.sharedBytes, isNotNull);
  });
}
