// Path: oss_packages/canvas_editor_flutter/test/editor_export_scene_boundary_test.dart

import 'dart:convert';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart';
import 'package:canvas_editor_flutter/src/editor_host_capabilities.dart';
import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart';
import 'package:canvas_editor_flutter/src/presentation/actions/editor_action_sets.dart';
import 'package:canvas_editor_flutter/src/presentation/actions/editor_actions.dart';
import 'package:canvas_editor_flutter/src/runtime/editor_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart'
    show CanvasPngSpec;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editor_runtime_fakes.dart';

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
    CanvasSceneDocument? outputScene,
  }) : _render = ValueNotifier<RenderSnapshot>(renderSnapshot),
       _document = ValueNotifier<CanvasSceneDocument>(document),
       _outputScene = outputScene ?? document;

  final ValueNotifier<RenderSnapshot> _render;
  final ValueNotifier<CanvasSceneDocument> _document;
  final CanvasSceneDocument _outputScene;
  final ValueNotifier<bool> _canUndo = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _canRedo = ValueNotifier<bool>(false);

  @override
  ValueListenable<RenderSnapshot> get render => _render;

  @override
  ValueListenable<CanvasSceneDocument> get document => _document;

  @override
  CanvasSceneDocument resolveSceneForOutput() => _outputScene;

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

class _RecordingPngExportPort implements PngExportPort {
  int shareCalls = 0;
  int saveCalls = 0;

  CanvasSceneDocument? scene;
  CanvasPngSpec? spec;
  String? filename;
  String? text;

  @override
  Future<String> sharePng({
    required CanvasSceneDocument scene,
    required CanvasPngSpec spec,
    required String filename,
    String? text,
  }) async {
    shareCalls++;
    this.scene = scene;
    this.spec = spec;
    this.filename = filename;
    this.text = text;
    return 'shared';
  }

  @override
  Future<String> savePng({
    required CanvasSceneDocument scene,
    required CanvasPngSpec spec,
    required String filename,
  }) async {
    saveCalls++;
    this.scene = scene;
    this.spec = spec;
    this.filename = filename;
    return 'saved';
  }
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

EditorActionContext _actionContext({
  required BuildContext context,
  required EditorController controller,
  required SelectionController selection,
}) {
  return EditorActionContext(
    buildContext: context,
    resources: canvasRuntimeResourcesForTest(),
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

final class _SourceDocument {
  const _SourceDocument(this.base);

  final CanvasSceneDocument base;
}

final class _ResolvingAdapter extends EditorDocumentAdapter<_SourceDocument> {
  const _ResolvingAdapter();

  @override
  CanvasSceneDocument getBase(_SourceDocument doc) => doc.base;

  @override
  _SourceDocument replaceBase(
    _SourceDocument doc,
    CanvasSceneDocument base,
  ) {
    return _SourceDocument(base);
  }

  @override
  CanvasSceneDocument resolve(_SourceDocument doc, Object? context) {
    final isCurrentContext = context == 'current';

    return doc.base.copyWith(
      artboardSize: isCurrentContext
          ? const Size2D(400, 200)
          : const Size2D(320, 160),
      backgroundOpacity: isCurrentContext ? 0.4 : 0.3,
    );
  }
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

    expect(decoded, equals(encodeCanvasScene(editableScene)));
  });

  testWidgets(
    'PNG share exports adapter-resolved scene without interactive preparation',
    (tester) async {
      final baseScene = _scene(0.1);
      final port = _RecordingPngExportPort();

      var preparerCalls = 0;

      final runtime = EditorRuntime<_SourceDocument>(
        initial: _SourceDocument(baseScene),
        adapter: const _ResolvingAdapter(),
        renderPipeline: CanvasRenderPipeline(
          textMeasurer: _FakeTextMeasurer(),
        ),
        initialContext: 'initial',
        scenePreparer: (scene, services) {
          preparerCalls++;
          return scene.copyWith(
            artboardSize: const Size2D(100, 400),
            backgroundOpacity: 0.9,
          );
        },
      );

      addTearDown(runtime.dispose);

      runtime.setResolveContext('current');
      await tester.pump();

      expect(runtime.document.value.artboardSize, const Size2D(300, 200));
      expect(runtime.document.value.backgroundOpacity, 0.1);
      expect(runtime.render.value.scene.artboardSize, const Size2D(100, 400));
      expect(runtime.render.value.scene.backgroundOpacity, 0.9);

      final preparerCallsBeforeExport = preparerCalls;

      final actions = pngExportActions(PngExportCapability(port: port));
      final shareAction = actions.singleWhere(
        (action) => action.id == EditorActionIds.sharePng,
      );

      final context = await _pumpContext(tester);
      final selection = SelectionController();
      addTearDown(selection.dispose);

      final ctx = _actionContext(
        context: context,
        controller: runtime,
        selection: selection,
      );

      await shareAction.invoke(ctx);

      expect(port.shareCalls, 1);
      expect(port.saveCalls, 0);
      expect(port.scene?.artboardSize, const Size2D(400, 200));
      expect(port.scene?.backgroundOpacity, 0.4);
      expect(
        preparerCalls,
        preparerCallsBeforeExport,
        reason: 'Editor PNG export must not invoke ScenePreparer.',
      );
      expect(port.spec?.widthPx, 2048);
      expect(port.spec?.heightPx, 1024);
      expect(port.spec?.fit, CanvasFit.contain);
      expect(port.spec?.pixelRatio, 2.0);
      expect(port.filename, 'canvas_export.png');
    },
  );

  testWidgets('PNG save delegates resolved scene to host port', (tester) async {
    final editableScene = _scene(0.1);
    final renderScene = _scene(0.9);
    final outputScene = CanvasSceneDocument(
      artboardSize: const Size2D(600, 300),
      backgroundFill: const CanvasFill.none(),
      backgroundOpacity: 0.4,
    );

    final port = _RecordingPngExportPort();
    final actions = pngExportActions(PngExportCapability(port: port));
    final saveAction = actions.singleWhere(
      (action) => action.id == EditorActionIds.savePng,
    );

    final context = await _pumpContext(tester);

    final controller = _FakeEditorController(
      renderSnapshot: _snapshotFor(renderScene),
      document: editableScene,
      outputScene: outputScene,
    );

    final selection = SelectionController();
    addTearDown(selection.dispose);
    addTearDown(controller.dispose);

    final ctx = _actionContext(
      context: context,
      controller: controller,
      selection: selection,
    );

    await saveAction.invoke(ctx);

    expect(port.shareCalls, 0);
    expect(port.saveCalls, 1);
    expect(identical(port.scene, outputScene), isTrue);
    expect(port.spec?.widthPx, 2048);
    expect(port.spec?.heightPx, 1024);
    expect(port.spec?.fit, CanvasFit.contain);
    expect(port.filename, 'canvas_export.png');
  });
}
