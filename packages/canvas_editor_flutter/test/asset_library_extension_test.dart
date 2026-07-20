// Path: oss_packages/canvas_editor_flutter/test/asset_library_extension_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/asset_library.dart';
import 'package:canvas_editor_flutter/extensions.dart';
import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class _NoopUiFeedback implements UiFeedback {
  @override
  void hideSpinner() {}

  @override
  void showSpinner() {}

  @override
  void toast(String msg) {}
}

final class _FakeTextMeasurer implements TextMeasurer {
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

final class _FakeEditorController implements EditorController {
  _FakeEditorController(CanvasSceneDocument scene)
    : _scene = scene,
      _render = ValueNotifier<RenderSnapshot>(_snapshotFor(scene)),
      _document = ValueNotifier<CanvasSceneDocument>(scene);

  CanvasSceneDocument _scene;

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
  ElementId? applyEdit(EditorEdit edit) {
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

final class _FakeMediaResolver implements CanvasMediaResolver {
  @override
  Future<Size2D?> resolveIntrinsicSize(String ref) async => null;

  @override
  Future<Map<String, Size2D>> resolveIntrinsicSizes(List<String> refs) async {
    return const <String, Size2D>{};
  }

  @override
  Future<String?> resolveUrl(String ref) async => null;

  @override
  Future<Map<String, String>> resolveUrls(List<String> refs) async {
    return const <String, String>{};
  }
}

final class _FakeFontAssets implements CanvasFontAssets {
  @override
  Iterable<String> get fallbackFontFamilies => const <String>[];

  @override
  List<FontDef> get loadableFonts => const <FontDef>[];

  @override
  List<FontDef> get pickerFonts => const <FontDef>[];

  @override
  Future<void> ensureLoaded(Iterable<String> families) async {}
}

final class _FakeIconCatalogPort implements IconCatalogPort {
  @override
  List<IconCatalogItem> get items => const <IconCatalogItem>[];

  @override
  Map<String, ResolvedIcon> get resolveMap => const <String, ResolvedIcon>{};

  @override
  ResolvedIcon? resolve(String iconRef) => null;
}

final class _Harness {
  const _Harness({
    required this.context,
    required this.controller,
    required this.selection,
  });

  final EditorActionContext context;
  final _FakeEditorController controller;
  final SelectionController selection;
}

Future<_Harness> _createHarness(WidgetTester tester) async {
  final controller = _FakeEditorController(_emptyScene());
  final selection = SelectionController();

  addTearDown(controller.dispose);
  addTearDown(selection.dispose);

  final context = EditorActionContext(
    buildContext: await _pumpBuildContext(tester),
    resources: _resources(),
    ui: _NoopUiFeedback(),
    controller: controller,
    selection: selection,
  );

  return _Harness(
    context: context,
    controller: controller,
    selection: selection,
  );
}

Future<BuildContext> _pumpBuildContext(WidgetTester tester) async {
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

CanvasRuntimeResources _resources() {
  return CanvasRuntimeResources(
    fonts: _FakeFontAssets(),
    icons: _FakeIconCatalogPort(),
    media: _FakeMediaResolver(),
  );
}

CanvasSceneDocument _emptyScene() {
  return const CanvasSceneDocument(
    artboardSize: Size2D(300, 200),
    backgroundFill: CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: <Node>[],
  );
}

RenderSnapshot _snapshotFor(CanvasSceneDocument scene) {
  final pipeline = CanvasRenderPipeline(textMeasurer: _FakeTextMeasurer());
  return defaultSceneRenderBuilder(pipeline, scene);
}

void main() {
  group('canvasAssetLibraryExtension', () {
    test('contributes one visible Assets action for a non-empty library', () {
      const library = LocalCanvasAssetLibrary(<CanvasAssetLibraryItem>[
        CanvasAssetLibraryItem(
          id: 'star',
          label: 'Star',
          category: 'stickers',
          sourceRef: 'asset:star.png',
          thumbnailRef: 'asset:star-thumb.png',
          intrinsicSize: Size2D(100, 100),
        ),
      ]);

      final extension = canvasAssetLibraryExtension<Object>(
        library: library,
        presentSelection: (_, _) async => null,
      );

      final action = extension.actionSpecs.single;

      expect(action.id.value, 'assetLibrary.open');
      expect(action.section, EditorToolbarSection.add);
      expect(action.labelBuilder(_toolbarState), 'Assets');
      expect(action.iconBuilder(_toolbarState), Icons.collections_outlined);
      expect(action.priority, 85);
      expect(action.isVisible(_toolbarState), isTrue);
      expect(action.isEnabled(_toolbarState), isTrue);
    });

    test('hides and disables Assets for an empty library', () {
      const library = LocalCanvasAssetLibrary(<CanvasAssetLibraryItem>[]);

      final extension = canvasAssetLibraryExtension<Object>(
        library: library,
        presentSelection: (_, _) async => null,
      );

      final action = extension.actionSpecs.single;

      expect(action.isVisible(_toolbarState), isFalse);
      expect(action.isEnabled(_toolbarState), isFalse);
    });

    testWidgets('cancellation does not edit or select anything', (
      tester,
    ) async {
      const library = LocalCanvasAssetLibrary(<CanvasAssetLibraryItem>[
        CanvasAssetLibraryItem(
          id: 'star',
          label: 'Star',
          category: 'stickers',
          sourceRef: 'asset:star.png',
          thumbnailRef: 'asset:star-thumb.png',
          intrinsicSize: Size2D(100, 100),
        ),
      ]);

      final harness = await _createHarness(tester);

      final extension = canvasAssetLibraryExtension<Object>(
        library: library,
        presentSelection: (_, _) async => null,
      );

      await extension.actionSpecs.single.invoke(harness.context);

      expect(harness.controller.document.value.children, isEmpty);
      expect(harness.selection.value.isEmpty, isTrue);
    });

    testWidgets(
      'persists sourceRef, preserves landscape ratio, centres, and selects',
      (tester) async {
        const selected = CanvasAssetLibraryItem(
          id: 'landscape',
          label: 'Landscape',
          category: 'photos',
          sourceRef: 'media:source-123',
          thumbnailRef: 'asset:thumb-landscape.png',
          intrinsicSize: Size2D(1200, 600),
        );

        final library = LocalCanvasAssetLibrary(const <CanvasAssetLibraryItem>[
          selected,
        ]);

        CanvasAssetLibrary? receivedLibrary;
        final harness = await _createHarness(tester);

        final extension = canvasAssetLibraryExtension<Object>(
          library: library,
          presentSelection: (_, candidateLibrary) async {
            receivedLibrary = candidateLibrary;
            return selected;
          },
        );

        await extension.actionSpecs.single.invoke(harness.context);

        expect(receivedLibrary, same(library));

        final inserted =
            harness.controller.document.value.children.single as ImageNode;

        final imageData = inserted.data;
        final insertedSize = imageData.size as Size2D;

        expect(imageData.sourcePath, selected.sourceRef);
        expect(imageData.sourcePath, isNot(selected.thumbnailRef));
        expect(insertedSize.w, closeTo(220, 0.001));
        expect(insertedSize.h, closeTo(110, 0.001));

        expect(inserted.xf.position.x, closeTo(150, 0.001));
        expect(inserted.xf.position.y, closeTo(100, 0.001));
        expect(harness.selection.firstId, inserted.id);
      },
    );

    testWidgets('preserves portrait aspect ratio', (tester) async {
      const selected = CanvasAssetLibraryItem(
        id: 'portrait',
        label: 'Portrait',
        category: 'photos',
        sourceRef: 'asset:portrait.png',
        thumbnailRef: 'asset:portrait-thumb.png',
        intrinsicSize: Size2D(600, 1200),
        defaultSize: 240,
      );

      final harness = await _createHarness(tester);

      final extension = canvasAssetLibraryExtension<Object>(
        library: const LocalCanvasAssetLibrary(<CanvasAssetLibraryItem>[
          selected,
        ]),
        presentSelection: (_, _) async => selected,
      );

      await extension.actionSpecs.single.invoke(harness.context);

      final inserted =
          harness.controller.document.value.children.single as ImageNode;

      final imageData = inserted.data;
      final insertedSize = imageData.size as Size2D;

      expect(insertedSize.w, closeTo(120, 0.001));
      expect(insertedSize.h, closeTo(240, 0.001));
    });
  });
}

const _toolbarState = EditorToolbarState(
  compact: false,
  canUndo: false,
  canRedo: false,
  hasSelection: false,
);
