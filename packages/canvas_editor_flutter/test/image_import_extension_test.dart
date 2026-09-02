// Path: oss_packages/canvas_editor_flutter/test/image_import_extension_test.dart

import 'dart:async';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/extensions.dart';
import 'package:canvas_editor_flutter/image_import.dart';
import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'editor_runtime_fakes.dart';

const _existingImageId = 'existing-image';
const _secondImageId = 'second-image';
const _existingAssetId = 'existing-asset';
const _sharedAssetId = 'shared-asset';
const _replaceGalleryKey = ValueKey('image-import-replace-gallery');
const _replaceCameraKey = ValueKey('image-import-replace-camera');

CanvasSceneDocument _sceneWithImage() {
  return const CanvasSceneDocument(
    artboardSize: Size2D(300, 200),
    backgroundFill: CanvasFill.none(),
    backgroundOpacity: 1.0,
    assets: <CanvasAssetId, CanvasImageAsset>{
      _existingAssetId: CanvasImageAsset(sourceRef: 'media:existing-image'),
    },
    children: <Node>[
      Node.image(
        id: _existingImageId,
        data: ImageData(assetId: _existingAssetId, size: Size2D(200, 160)),
      ),
    ],
  );
}

CanvasSceneDocument _sceneWithTwoImagesSharingSource() {
  return const CanvasSceneDocument(
    artboardSize: Size2D(300, 200),
    backgroundFill: CanvasFill.none(),
    backgroundOpacity: 1.0,
    assets: <CanvasAssetId, CanvasImageAsset>{
      _sharedAssetId: CanvasImageAsset(sourceRef: 'media:shared-image'),
    },
    children: <Node>[
      Node.image(
        id: _existingImageId,
        data: ImageData(assetId: _sharedAssetId, size: Size2D(200, 160)),
      ),
      Node.image(
        id: _secondImageId,
        data: ImageData(assetId: _sharedAssetId, size: Size2D(120, 100)),
      ),
    ],
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

final class _RecordingImageImportPort implements ImageImportPort {
  _RecordingImageImportPort(this.result);

  ImageImportResult result;
  final List<ImageImportSource> requestedSources = <ImageImportSource>[];

  @override
  Future<ImageImportResult> importImage({required ImageImportSource source}) async {
    requestedSources.add(source);
    return result;
  }
}

final class _DeferredImageImportPort implements ImageImportPort {
  final List<ImageImportSource> requestedSources = <ImageImportSource>[];
  final Completer<ImageImportResult> _completer =
      Completer<ImageImportResult>();

  @override
  Future<ImageImportResult> importImage({required ImageImportSource source}) {
    requestedSources.add(source);
    return _completer.future;
  }

  void complete(ImageImportResult result) {
    _completer.complete(result);
  }
}

final class _SizedImageResolver implements CanvasImageAssetResolver {
  _SizedImageResolver(this.sizes);

  final Map<String, Size2D> sizes;
  final List<String> requestedIntrinsicSizes = <String>[];

  @override
  Future<Map<String, String>> resolveSources(List<String> sourceRefs) async {
    return const <String, String>{};
  }

  @override
  Future<Map<String, Size2D>> resolveIntrinsicSizes(
    List<String> sourceRefs,
  ) async {
    requestedIntrinsicSizes.addAll(sourceRefs);

    return <String, Size2D>{
      for (final sourceRef in sourceRefs)
        if (sizes.containsKey(sourceRef)) sourceRef: sizes[sourceRef]!,
    };
  }
}

final class _PendingImageResolver implements CanvasImageAssetResolver {
  final Completer<Map<String, Size2D>> intrinsicSizes =
      Completer<Map<String, Size2D>>();

  final List<String> requestedIntrinsicSizes = <String>[];

  @override
  Future<Map<String, String>> resolveSources(List<String> sourceRefs) async {
    return const <String, String>{};
  }

  @override
  Future<Map<String, Size2D>> resolveIntrinsicSizes(
    List<String> sourceRefs,
  ) {
    requestedIntrinsicSizes.addAll(sourceRefs);
    return intrinsicSizes.future;
  }
}

final class _AdditiveImageSectionExtension
    extends EditorExtension<CanvasSceneDocument> {
  @override
  EditorSurfaceFeatures get surfaceFeatures {
    return EditorSurfaceFeatures(
      inspectorSections: <InspectorSectionBuilder>[
        (context) {
          final selected =
              context.selectedRenderedNode ?? context.selectedEditableNode;

          if (selected is! ImageNode) return null;

          return const Text('Extra image section');
        },
      ],
    );
  }
}

final class _LaterImagePanelExtension
    extends EditorExtension<CanvasSceneDocument> {
  @override
  EditorSurfaceFeatures get surfaceFeatures {
    return EditorSurfaceFeatures(
      inspectorBuilder: (context) {
        final selected =
            context.selectedRenderedNode ?? context.selectedEditableNode;

        if (selected is! ImageNode) return null;

        return const Text('Later image panel');
      },
    );
  }
}

final class _MountedEditor {
  const _MountedEditor({
    required this.actions,
    required this.controller,
    required this.selection,
  });

  final EditorActionDispatcher actions;
  final EditorController controller;
  final SelectionController selection;
}

Future<_MountedEditor> _pumpEditor(
  WidgetTester tester, {
  required CanvasSceneDocument scene,
  required ImageImportPort imageImport,
  CanvasRuntimeResources? resources,
  List<EditorExtension<CanvasSceneDocument>> extraExtensions =
      const <EditorExtension<CanvasSceneDocument>>[],
}) async {
  EditorActionDispatcher? capturedActions;

  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox.expand(
        child: CanvasSceneEditor(
          initialScene: scene,
          resources: resources ?? canvasRuntimeResourcesForTest(),
          extensions: <EditorExtension<CanvasSceneDocument>>[
            imageImportExtension<CanvasSceneDocument>(imageImport: imageImport),
            ...extraExtensions,
          ],
          appBarBuilder: (_, _, actions, _) {
            capturedActions = actions;

            return const PreferredSize(
              preferredSize: Size.zero,
              child: SizedBox.shrink(),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final scaffoldContext = tester.element(find.byType(Scaffold).first);

  return _MountedEditor(
    actions: capturedActions!,
    controller: scaffoldContext.read<EditorController>(),
    selection: Provider.of<SelectionController>(scaffoldContext, listen: false),
  );
}

ImageNode _singleImage(EditorController controller) {
  return controller.document.value.children.single as ImageNode;
}

String? _imageSourceRef(EditorController controller, String imageId) {
  final scene = controller.document.value;
  final image = findById(scene, imageId);
  if (image is! ImageNode) return null;

  final assetId = image.data.assetId;
  return assetId == null ? null : scene.assets[assetId]?.sourceRef;
}

CanvasImageAsset? _imageAsset(EditorController controller, String imageId) {
  final scene = controller.document.value;
  final image = findById(scene, imageId);
  if (image is! ImageNode) return null;

  final assetId = image.data.assetId;
  return assetId == null ? null : scene.assets[assetId];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'import extension replaces an image source and retains shared geometry controls',
    (tester) async {
      final imageImport = _RecordingImageImportPort(
        ImageImportResult.success('media:replacement-image'),
      );

      final editor = await _pumpEditor(
        tester,
        scene: _sceneWithImage(),
        imageImport: imageImport,
      );

      editor.selection.selectItems(const <String>[_existingImageId]);
      await tester.pumpAndSettle();

      expect(find.byKey(_replaceGalleryKey), findsOneWidget);
      expect(find.byKey(_replaceCameraKey), findsOneWidget);
      expect(find.text('Width: 200'), findsOneWidget);
      expect(find.text('Height: 160'), findsOneWidget);

      await tester.tap(find.byKey(_replaceGalleryKey));
      await tester.pumpAndSettle();

      expect(imageImport.requestedSources, <ImageImportSource>[
        ImageImportSource.gallery,
      ]);
      expect(
        _imageSourceRef(editor.controller, _existingImageId),
        'media:replacement-image',
      );
      expect(editor.controller.canUndo.value, isTrue);

      editor.controller.undo();
      await tester.pumpAndSettle();

      expect(
        _imageSourceRef(editor.controller, _existingImageId),
        'media:existing-image',
      );
    },
  );

  testWidgets(
    'image import coexists with later additive Image content and intrinsic geometry',
    (tester) async {
      final imageImport = _RecordingImageImportPort(
        ImageImportResult.success('media:unused'),
      );

      final editor = await _pumpEditor(
        tester,
        scene: _sceneWithImage(),
        imageImport: imageImport,
        extraExtensions: <EditorExtension<CanvasSceneDocument>>[
          _AdditiveImageSectionExtension(),
        ],
      );

      editor.selection.selectItems(const <String>[_existingImageId]);
      await tester.pumpAndSettle();

      expect(find.byKey(_replaceGalleryKey), findsOneWidget);
      expect(find.text('Extra image section'), findsOneWidget);
      expect(find.text('Width: 200'), findsOneWidget);
      expect(find.text('Height: 160'), findsOneWidget);

      final sourceTop = tester.getTopLeft(find.byKey(_replaceGalleryKey)).dy;
      final extraTop = tester.getTopLeft(find.text('Extra image section')).dy;
      final geometryTop = tester.getTopLeft(find.text('Width: 200')).dy;

      expect(sourceTop, lessThan(extraTop));
      expect(extraTop, lessThan(geometryTop));
    },
  );

  testWidgets('cancelled replacement leaves the document unchanged', (
    tester,
  ) async {
    final imageImport = _RecordingImageImportPort(
      const ImageImportResult.cancelled(),
    );

    final editor = await _pumpEditor(
      tester,
      scene: _sceneWithImage(),
      imageImport: imageImport,
    );

    editor.selection.selectItems(const <String>[_existingImageId]);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_replaceGalleryKey));
    await tester.pumpAndSettle();

    expect(imageImport.requestedSources, <ImageImportSource>[
      ImageImportSource.gallery,
    ]);
    expect(
      _imageSourceRef(editor.controller, _existingImageId),
      'media:existing-image',
    );
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'failed replacement leaves the document unchanged and shows feedback',
    (tester) async {
      final imageImport = _RecordingImageImportPort(
        ImageImportResult.failure('Upload failed'),
      );

      final editor = await _pumpEditor(
        tester,
        scene: _sceneWithImage(),
        imageImport: imageImport,
      );

      editor.selection.selectItems(const <String>[_existingImageId]);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_replaceGalleryKey));
      await tester.pump();

      expect(
        _imageSourceRef(editor.controller, _existingImageId),
        'media:existing-image',
      );
      expect(
        find.text('Failed to replace image: Upload failed'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'pending replacement cannot migrate to a newly selected image with the same source',
    (tester) async {
      final imageImport = _DeferredImageImportPort();

      final editor = await _pumpEditor(
        tester,
        scene: _sceneWithTwoImagesSharingSource(),
        imageImport: imageImport,
      );

      editor.selection.selectItems(const <String>[_existingImageId]);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_replaceGalleryKey));
      await tester.pump();

      expect(imageImport.requestedSources, <ImageImportSource>[
        ImageImportSource.gallery,
      ]);

      editor.selection.selectItems(const <String>[_secondImageId]);
      await tester.pump();

      imageImport.complete(
        ImageImportResult.success('media:stale-replacement'),
      );
      await tester.pumpAndSettle();

      expect(
        _imageSourceRef(editor.controller, _existingImageId),
        'media:shared-image',
      );
      expect(
        _imageSourceRef(editor.controller, _secondImageId),
        'media:shared-image',
      );
    },
  );

  testWidgets(
    'pending replacement is discarded when the canonical source changes',
    (tester) async {
      final imageImport = _DeferredImageImportPort();

      final editor = await _pumpEditor(
        tester,
        scene: _sceneWithImage(),
        imageImport: imageImport,
      );

      editor.selection.selectItems(const <String>[_existingImageId]);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_replaceGalleryKey));
      await tester.pump();

      editor.controller.commitField<String>(
        _existingImageId,
        CanvasFields.imageSource,
        'media:newer-source',
      );
      await tester.pump();

      imageImport.complete(
        ImageImportResult.success('media:stale-replacement'),
      );
      await tester.pumpAndSettle();

      expect(
        _imageSourceRef(editor.controller, _existingImageId),
        'media:newer-source',
      );
    },
  );

  testWidgets(
    'Add Image imports a durable source before creating and selecting one node',
    (tester) async {
      final imageImport = _RecordingImageImportPort(
        ImageImportResult.success('media:added-image'),
      );

      final editor = await _pumpEditor(
        tester,
        scene: _emptyScene(),
        imageImport: imageImport,
      );

      editor.actions.invoke(EditorActionIds.addImage);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('image-import-add-gallery')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('image-import-add-gallery')));
      await tester.pumpAndSettle();

      expect(imageImport.requestedSources, <ImageImportSource>[
        ImageImportSource.gallery,
      ]);

      final image = _singleImage(editor.controller);
      final size = image.data.size;

      expect(_imageSourceRef(editor.controller, image.id), 'media:added-image');
      expect(image.data.assetId, isNotNull);
      expect(size.w, 200);
      expect(size.h, 200);
      expect(image.xf.position.x, 180);
      expect(image.xf.position.y, 180);
      expect(editor.selection.firstId, image.id);
      expect(editor.controller.canUndo.value, isTrue);
    },
  );

  testWidgets('Add Image preserves resolved intrinsic aspect ratio', (
    tester,
  ) async {
    final imageImport = _RecordingImageImportPort(
      ImageImportResult.success('media:wide-image'),
    );
    final images = _SizedImageResolver(const <String, Size2D>{
      'media:wide-image': Size2D(800, 400),
    });

    final editor = await _pumpEditor(
      tester,
      scene: _emptyScene(),
      imageImport: imageImport,
      resources: canvasRuntimeResourcesForTest(images: images),
    );

    editor.actions.invoke(EditorActionIds.addImage);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('image-import-add-gallery')));
    await tester.pumpAndSettle();

    final image = _singleImage(editor.controller);

    expect(images.requestedIntrinsicSizes, <String>['media:wide-image']);
    expect(image.data.size, const Size2D(200, 100));
    expect(image.xf.position, const Vec2(180, 130));
    expect(
      _imageAsset(editor.controller, image.id)?.intrinsicSize,
      const Size2D(800, 400),
    );
  });

  testWidgets(
    'Add Image falls back when intrinsic metadata does not complete',
    (tester) async {
      final imageImport = _RecordingImageImportPort(
        ImageImportResult.success('media:pending-image'),
      );
      final images = _PendingImageResolver();

      final editor = await _pumpEditor(
        tester,
        scene: _emptyScene(),
        imageImport: imageImport,
        resources: canvasRuntimeResourcesForTest(images: images),
      );

      editor.actions.invoke(EditorActionIds.addImage);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('image-import-add-gallery')));
      await tester.pump();

      expect(editor.controller.document.value.children, isEmpty);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      final image = _singleImage(editor.controller);

      expect(image.data.size, const Size2D(200, 200));
      expect(image.xf.position, const Vec2(180, 180));
      expect(_imageAsset(editor.controller, image.id)?.intrinsicSize, isNull);
      expect(editor.selection.firstId, image.id);

      images.intrinsicSizes.complete(const <String, Size2D>{});
      await tester.pump();
    },
  );

  testWidgets('dismissing Add Image leaves the document untouched', (
    tester,
  ) async {
    final imageImport = _RecordingImageImportPort(
      ImageImportResult.success('media:should-not-be-used'),
    );

    final editor = await _pumpEditor(
      tester,
      scene: _emptyScene(),
      imageImport: imageImport,
    );

    editor.actions.invoke(EditorActionIds.addImage);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('image-import-add-cancel')));
    await tester.pumpAndSettle();

    expect(imageImport.requestedSources, isEmpty);
    expect(editor.controller.document.value.children, isEmpty);
    expect(editor.selection.value.isEmpty, isTrue);
    expect(editor.controller.canUndo.value, isFalse);
  });

  testWidgets('failed Add Image creates no node and reports feedback', (
    tester,
  ) async {
    final imageImport = _RecordingImageImportPort(
      ImageImportResult.failure('Upload failed'),
    );

    final editor = await _pumpEditor(
      tester,
      scene: _emptyScene(),
      imageImport: imageImport,
    );

    editor.actions.invoke(EditorActionIds.addImage);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('image-import-add-camera')));
    await tester.pump();

    expect(imageImport.requestedSources, <ImageImportSource>[
      ImageImportSource.camera,
    ]);
    expect(editor.controller.document.value.children, isEmpty);
    expect(editor.selection.value.isEmpty, isTrue);
    expect(find.text('Failed to add image: Upload failed'), findsOneWidget);
  });

  testWidgets(
    'exclusive Image inspector suppresses additive and intrinsic Image content',
    (tester) async {
      final imageImport = _RecordingImageImportPort(
        ImageImportResult.success('media:unused'),
      );

      final editor = await _pumpEditor(
        tester,
        scene: _sceneWithImage(),
        imageImport: imageImport,
        extraExtensions: <EditorExtension<CanvasSceneDocument>>[
          _LaterImagePanelExtension(),
        ],
      );

      editor.selection.selectItems(const <String>[_existingImageId]);
      await tester.pumpAndSettle();

      expect(find.text('Later image panel'), findsOneWidget);
      expect(find.byKey(_replaceGalleryKey), findsNothing);
      expect(find.byKey(_replaceCameraKey), findsNothing);
      expect(find.text('Width: 200'), findsNothing);
    },
  );
}
