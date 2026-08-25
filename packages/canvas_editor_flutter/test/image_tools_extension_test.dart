import 'dart:async';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/extensions.dart';
import 'package:canvas_editor_flutter/image_import.dart';
import 'package:canvas_editor_flutter/image_tools.dart';
import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'editor_runtime_fakes.dart';

const _imageA = 'image-a';
const _imageB = 'image-b';
const _assetA = 'asset-a';
const _sharedAsset = 'shared-asset';
const _textId = 'text-a';
const _removeButtonKey = ValueKey('remove-background-button');

CanvasSceneDocument _singleImageScene({String? sourceRef = 'media:original'}) {
  return CanvasSceneDocument(
    artboardSize: const Size2D(300, 200),
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1,
    assets: sourceRef == null
        ? const <CanvasAssetId, CanvasImageAsset>{}
        : <CanvasAssetId, CanvasImageAsset>{
            _assetA: CanvasImageAsset(sourceRef: sourceRef),
          },
    children: <Node>[
      Node.image(
        id: _imageA,
        data: ImageData(
          assetId: sourceRef == null ? null : _assetA,
          size: const Size2D(200, 160),
        ),
      ),
    ],
  );
}

CanvasSceneDocument _twoImageScene() {
  return const CanvasSceneDocument(
    artboardSize: Size2D(300, 200),
    backgroundFill: CanvasFill.none(),
    backgroundOpacity: 1,
    assets: <CanvasAssetId, CanvasImageAsset>{
      _sharedAsset: CanvasImageAsset(sourceRef: 'media:shared'),
    },
    children: <Node>[
      Node.image(
        id: _imageA,
        data: ImageData(assetId: _sharedAsset, size: Size2D(200, 160)),
      ),
      Node.image(
        id: _imageB,
        data: ImageData(assetId: _sharedAsset, size: Size2D(120, 100)),
      ),
    ],
  );
}

CanvasSceneDocument _textScene() {
  return const CanvasSceneDocument(
    artboardSize: Size2D(300, 200),
    backgroundFill: CanvasFill.none(),
    backgroundOpacity: 1,
    children: <Node>[
      Node.text(
        id: _textId,
        data: TextData(
          text: 'Text',
          fontFamily: 'Inter',
          fontWeight: 400,
          fontSize: 24,
          letterSpacing: 0,
          fill: CanvasFill.solid(0xFF111111),
        ),
      ),
    ],
  );
}

final class _RecordingBackgroundRemovalPort implements BackgroundRemovalPort {
  _RecordingBackgroundRemovalPort(this.result);

  BackgroundRemovalResult result;
  final List<String> sourceRefs = <String>[];

  @override
  Future<BackgroundRemovalResult> removeBackground({
    required String sourceRef,
  }) async {
    sourceRefs.add(sourceRef);
    return result;
  }
}

final class _DeferredBackgroundRemovalPort implements BackgroundRemovalPort {
  final List<String> sourceRefs = <String>[];
  final Completer<BackgroundRemovalResult> _completer =
      Completer<BackgroundRemovalResult>();

  @override
  Future<BackgroundRemovalResult> removeBackground({
    required String sourceRef,
  }) {
    sourceRefs.add(sourceRef);
    return _completer.future;
  }

  void complete(BackgroundRemovalResult result) {
    _completer.complete(result);
  }
}

final class _ThrowingBackgroundRemovalPort implements BackgroundRemovalPort {
  @override
  Future<BackgroundRemovalResult> removeBackground({
    required String sourceRef,
  }) {
    throw StateError('provider internals must not leak');
  }
}

final class _NoopImageImportPort implements ImageImportPort {
  @override
  Future<ImageImportResult> importImage({
    required ImageImportSource source,
  }) async {
    return const ImageImportResult.cancelled();
  }
}

final class _ExclusiveImageInspectorExtension
    extends EditorExtension<CanvasSceneDocument> {
  @override
  EditorSurfaceFeatures get surfaceFeatures {
    return EditorSurfaceFeatures(
      inspectorBuilder: (context) {
        final selected =
            context.selectedRenderedNode ?? context.selectedEditableNode;

        if (selected is! ImageNode) return null;
        return const Text('Exclusive image inspector');
      },
    );
  }
}

final class _PolicyDocument {
  const _PolicyDocument({required this.base});

  final CanvasSceneDocument base;
}

final class _ImageSourceDeniedAdapter
    extends EditorDocumentAdapter<_PolicyDocument> {
  const _ImageSourceDeniedAdapter();

  @override
  CanvasSceneDocument getBase(_PolicyDocument document) => document.base;

  @override
  _PolicyDocument replaceBase(
    _PolicyDocument document,
    CanvasSceneDocument base,
  ) {
    return _PolicyDocument(base: base);
  }

  @override
  CanvasSceneDocument resolve(_PolicyDocument document, Object? context) {
    return document.base;
  }

  @override
  String? fieldEditDisabledReason(
    _PolicyDocument document,
    ElementId nodeId,
    CanvasFieldKey fieldKey,
  ) {
    if (nodeId == _imageA && fieldKey == CanvasFields.imageSource) {
      return 'Bound to brand.logo';
    }

    return null;
  }
}

final class _MountedEditor {
  const _MountedEditor({required this.controller, required this.selection});

  final EditorController controller;
  final SelectionController selection;
}

Future<_MountedEditor> _pumpSceneEditor(
  WidgetTester tester, {
  required CanvasSceneDocument scene,
  required List<EditorExtension<CanvasSceneDocument>> extensions,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox.expand(
        child: CanvasSceneEditor(
          initialScene: scene,
          resources: canvasRuntimeResourcesForTest(),
          extensions: extensions,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _mountedEditor(tester);
}

Future<_MountedEditor> _pumpDeniedEditor(
  WidgetTester tester, {
  required BackgroundRemovalPort port,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox.expand(
        child: CanvasEditorSurface<_PolicyDocument>(
          initialDocument: _PolicyDocument(base: _singleImageScene()),
          adapter: const _ImageSourceDeniedAdapter(),
          resources: canvasRuntimeResourcesForTest(),
          extensions: <EditorExtension<_PolicyDocument>>[
            backgroundRemovalExtension<_PolicyDocument>(port: port),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _mountedEditor(tester);
}

_MountedEditor _mountedEditor(WidgetTester tester) {
  final scaffoldContext = tester.element(find.byType(Scaffold).first);

  return _MountedEditor(
    controller: scaffoldContext.read<EditorController>(),
    selection: Provider.of<SelectionController>(scaffoldContext, listen: false),
  );
}

ImageNode _imageById(EditorController controller, ElementId id) {
  final node = findById(controller.document.value, id);
  expect(node, isA<ImageNode>());
  return node! as ImageNode;
}

String? _imageSourceRef(EditorController controller, ElementId id) {
  final scene = controller.document.value;
  final image = findById(scene, id);
  if (image is! ImageNode) return null;

  final assetId = image.data.assetId;
  return assetId == null ? null : scene.assets[assetId]?.sourceRef;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'successful background removal commits imageSource and is undoable',
    (tester) async {
      final port = _RecordingBackgroundRemovalPort(
        const BackgroundRemovalSuccess(sourceRef: 'media:foreground'),
      );

      final editor = await _pumpSceneEditor(
        tester,
        scene: _singleImageScene(),
        extensions: <EditorExtension<CanvasSceneDocument>>[
          backgroundRemovalExtension<CanvasSceneDocument>(port: port),
        ],
      );

      editor.selection.selectItems(const <String>[_imageA]);
      await tester.pumpAndSettle();

      expect(find.text('Image tools'), findsOneWidget);
      expect(find.byKey(_removeButtonKey), findsOneWidget);

      await tester.tap(find.byKey(_removeButtonKey));
      await tester.pumpAndSettle();

      expect(port.sourceRefs, <String>['media:original']);
      expect(_imageSourceRef(editor.controller, _imageA), 'media:foreground');
      expect(editor.controller.canUndo.value, isTrue);

      editor.controller.undo();
      await tester.pumpAndSettle();
      expect(_imageSourceRef(editor.controller, _imageA), 'media:original');

      editor.controller.redo();
      await tester.pumpAndSettle();
      expect(_imageSourceRef(editor.controller, _imageA), 'media:foreground');
    },
  );

  testWidgets('non-image selection has no Image tools section', (tester) async {
    final port = _RecordingBackgroundRemovalPort(
      const BackgroundRemovalSuccess(sourceRef: 'media:unused'),
    );

    final editor = await _pumpSceneEditor(
      tester,
      scene: _textScene(),
      extensions: <EditorExtension<CanvasSceneDocument>>[
        backgroundRemovalExtension<CanvasSceneDocument>(port: port),
      ],
    );

    editor.selection.selectItems(const <String>[_textId]);
    await tester.pumpAndSettle();

    expect(find.text('Image tools'), findsNothing);
    expect(find.byKey(_removeButtonKey), findsNothing);
    expect(port.sourceRefs, isEmpty);
  });

  testWidgets(
    'image import, Image tools, and intrinsic geometry coexist in order',
    (tester) async {
      final port = _RecordingBackgroundRemovalPort(
        const BackgroundRemovalFailure(
          kind: BackgroundRemovalFailureKind.unsupported,
        ),
      );

      final editor = await _pumpSceneEditor(
        tester,
        scene: _singleImageScene(),
        extensions: <EditorExtension<CanvasSceneDocument>>[
          imageImportExtension<CanvasSceneDocument>(
            imageImport: _NoopImageImportPort(),
          ),
          backgroundRemovalExtension<CanvasSceneDocument>(port: port),
        ],
      );

      editor.selection.selectItems(const <String>[_imageA]);
      await tester.pumpAndSettle();

      final sourceFinder = find.byKey(
        const ValueKey('image-import-replace-gallery'),
      );
      final toolsFinder = find.text('Image tools');
      final geometryFinder = find.text('Width: 200');

      expect(sourceFinder, findsOneWidget);
      expect(toolsFinder, findsOneWidget);
      expect(geometryFinder, findsOneWidget);
      expect(find.text('Height: 160'), findsOneWidget);

      expect(
        tester.getTopLeft(sourceFinder).dy,
        lessThan(tester.getTopLeft(toolsFinder).dy),
      );
      expect(
        tester.getTopLeft(toolsFinder).dy,
        lessThan(tester.getTopLeft(geometryFinder).dy),
      );
    },
  );

  testWidgets('exclusive inspector suppresses Image tools', (tester) async {
    final port = _RecordingBackgroundRemovalPort(
      const BackgroundRemovalSuccess(sourceRef: 'media:unused'),
    );

    final editor = await _pumpSceneEditor(
      tester,
      scene: _singleImageScene(),
      extensions: <EditorExtension<CanvasSceneDocument>>[
        backgroundRemovalExtension<CanvasSceneDocument>(port: port),
        _ExclusiveImageInspectorExtension(),
      ],
    );

    editor.selection.selectItems(const <String>[_imageA]);
    await tester.pumpAndSettle();

    expect(find.text('Exclusive image inspector'), findsOneWidget);
    expect(find.text('Image tools'), findsNothing);
    expect(find.byKey(_removeButtonKey), findsNothing);
  });

  testWidgets(
    'runtime field denial disables the tool and shows the exact reason',
    (tester) async {
      final port = _RecordingBackgroundRemovalPort(
        const BackgroundRemovalSuccess(sourceRef: 'media:unused'),
      );

      final editor = await _pumpDeniedEditor(tester, port: port);

      editor.selection.selectItems(const <String>[_imageA]);
      await tester.pumpAndSettle();

      expect(find.text('Bound to brand.logo'), findsOneWidget);

      final button = tester.widget<OutlinedButton>(
        find.byKey(_removeButtonKey),
      );
      expect(button.onPressed, isNull);
      expect(port.sourceRefs, isEmpty);
    },
  );

  testWidgets('effective source mismatch disables background removal', (
    tester,
  ) async {
    final port = _RecordingBackgroundRemovalPort(
      const BackgroundRemovalSuccess(sourceRef: 'media:foreground'),
    );

    final preparer = StaticEditorExtension<CanvasSceneDocument>(
      scenePreparer: (scene, _) {
        final node = findById(scene, _imageA);
        if (node is! ImageNode) return scene;

        const preparedAssetId = 'prepared-asset';
        final nextScene = scene.copyWith(
          assets: <CanvasAssetId, CanvasImageAsset>{
            ...scene.assets,
            preparedAssetId: const CanvasImageAsset(
              sourceRef: 'media:prepared',
            ),
          },
        );

        return replaceById(
          nextScene,
          _imageA,
          node.copyWith(
            data: node.data.copyWith(assetId: preparedAssetId),
          ),
        );
      },
    );

    final editor = await _pumpSceneEditor(
      tester,
      scene: _singleImageScene(),
      extensions: <EditorExtension<CanvasSceneDocument>>[
        preparer,
        backgroundRemovalExtension<CanvasSceneDocument>(port: port),
      ],
    );

    editor.selection.selectItems(const <String>[_imageA]);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This image source is resolved at runtime and cannot be '
        'transformed directly.',
      ),
      findsOneWidget,
    );

    final button = tester.widget<OutlinedButton>(find.byKey(_removeButtonKey));
    expect(button.onPressed, isNull);
    expect(port.sourceRefs, isEmpty);
  });

  testWidgets(
    'pending result cannot migrate to another image with the same source',
    (tester) async {
      final port = _DeferredBackgroundRemovalPort();

      final editor = await _pumpSceneEditor(
        tester,
        scene: _twoImageScene(),
        extensions: <EditorExtension<CanvasSceneDocument>>[
          backgroundRemovalExtension<CanvasSceneDocument>(port: port),
        ],
      );

      editor.selection.selectItems(const <String>[_imageA]);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_removeButtonKey));
      await tester.pump();
      expect(port.sourceRefs, <String>['media:shared']);

      editor.selection.selectItems(const <String>[_imageB]);
      await tester.pump();

      port.complete(
        const BackgroundRemovalSuccess(sourceRef: 'media:stale-result'),
      );
      await tester.pumpAndSettle();

      expect(_imageSourceRef(editor.controller, _imageA), 'media:shared');
      expect(_imageSourceRef(editor.controller, _imageB), 'media:shared');
    },
  );

  testWidgets('pending result is discarded when the canonical source changes', (
    tester,
  ) async {
    final port = _DeferredBackgroundRemovalPort();

    final editor = await _pumpSceneEditor(
      tester,
      scene: _singleImageScene(),
      extensions: <EditorExtension<CanvasSceneDocument>>[
        backgroundRemovalExtension<CanvasSceneDocument>(port: port),
      ],
    );

    editor.selection.selectItems(const <String>[_imageA]);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_removeButtonKey));
    await tester.pump();

    editor.controller.commitField<String>(
      _imageA,
      CanvasFields.imageSource,
      'media:newer-source',
    );
    await tester.pump();

    port.complete(
      const BackgroundRemovalSuccess(sourceRef: 'media:stale-result'),
    );
    await tester.pumpAndSettle();

    expect(_imageSourceRef(editor.controller, _imageA), 'media:newer-source');
  });

  testWidgets('pending result is safe when the target is deleted', (
    tester,
  ) async {
    final port = _DeferredBackgroundRemovalPort();

    final editor = await _pumpSceneEditor(
      tester,
      scene: _singleImageScene(),
      extensions: <EditorExtension<CanvasSceneDocument>>[
        backgroundRemovalExtension<CanvasSceneDocument>(port: port),
      ],
    );

    editor.selection.selectItems(const <String>[_imageA]);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_removeButtonKey));
    await tester.pump();

    editor.controller.applyEdit(EditorEdits.deleteSubtree(_imageA));
    await tester.pump();

    port.complete(
      const BackgroundRemovalSuccess(sourceRef: 'media:stale-result'),
    );
    await tester.pumpAndSettle();

    expect(findById(editor.controller.document.value, _imageA), isNull);
  });

  testWidgets('same-source success is rejected without creating an edit', (
    tester,
  ) async {
    final port = _RecordingBackgroundRemovalPort(
      const BackgroundRemovalSuccess(sourceRef: 'media:original'),
    );

    final editor = await _pumpSceneEditor(
      tester,
      scene: _singleImageScene(),
      extensions: <EditorExtension<CanvasSceneDocument>>[
        backgroundRemovalExtension<CanvasSceneDocument>(port: port),
      ],
    );

    editor.selection.selectItems(const <String>[_imageA]);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_removeButtonKey));
    await tester.pump();

    expect(_imageSourceRef(editor.controller, _imageA), 'media:original');
    expect(editor.controller.canUndo.value, isFalse);
    expect(
      find.text(
        'Background removal did not return a usable replacement image.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('typed failure creates no edit and shows safe feedback', (
    tester,
  ) async {
    final port = _RecordingBackgroundRemovalPort(
      const BackgroundRemovalFailure(
        kind: BackgroundRemovalFailureKind.failed,
        message: 'Could not process this image.',
      ),
    );

    final editor = await _pumpSceneEditor(
      tester,
      scene: _singleImageScene(),
      extensions: <EditorExtension<CanvasSceneDocument>>[
        backgroundRemovalExtension<CanvasSceneDocument>(port: port),
      ],
    );

    editor.selection.selectItems(const <String>[_imageA]);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_removeButtonKey));
    await tester.pump();

    expect(_imageSourceRef(editor.controller, _imageA), 'media:original');
    expect(editor.controller.canUndo.value, isFalse);
    expect(find.text('Could not process this image.'), findsOneWidget);
  });

  testWidgets('thrown provider exception is replaced with generic feedback', (
    tester,
  ) async {
    final editor = await _pumpSceneEditor(
      tester,
      scene: _singleImageScene(),
      extensions: <EditorExtension<CanvasSceneDocument>>[
        backgroundRemovalExtension<CanvasSceneDocument>(
          port: _ThrowingBackgroundRemovalPort(),
        ),
      ],
    );

    editor.selection.selectItems(const <String>[_imageA]);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_removeButtonKey));
    await tester.pump();

    expect(_imageSourceRef(editor.controller, _imageA), 'media:original');
    expect(editor.controller.canUndo.value, isFalse);
    expect(
      find.text('Unable to remove the background. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('provider internals'), findsNothing);
  });
}
