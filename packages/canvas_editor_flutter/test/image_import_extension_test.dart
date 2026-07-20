// Path: oss_packages/canvas_editor_flutter/test/image_import_extension_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/extensions.dart';
import 'package:canvas_editor_flutter/image_import.dart';
import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'editor_runtime_fakes.dart';

const _existingImageId = 'existing-image';

CanvasSceneDocument _sceneWithImage() {
  return const CanvasSceneDocument(
    artboardSize: Size2D(300, 200),
    backgroundFill: CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: <Node>[
      Node.image(
        id: _existingImageId,
        data: ImageData(
          sourcePath: 'media:existing-image',
          size: Size2D(200, 160),
        ),
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
  Future<ImageImportResult> importImage({
    required ImageImportSource source,
  }) async {
    requestedSources.add(source);
    return result;
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
  List<EditorExtension<CanvasSceneDocument>> extraExtensions =
      const <EditorExtension<CanvasSceneDocument>>[],
}) async {
  EditorActionDispatcher? capturedActions;

  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox.expand(
        child: CanvasSceneEditor(
          initialScene: scene,
          resources: canvasRuntimeResourcesForTest(),
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

      expect(find.text('Pick from gallery'), findsOneWidget);
      expect(find.text('Capture from camera'), findsOneWidget);
      expect(find.text('Width: 200'), findsOneWidget);
      expect(find.text('Height: 160'), findsOneWidget);

      await tester.tap(find.text('Pick from gallery'));
      await tester.pumpAndSettle();

      expect(imageImport.requestedSources, <ImageImportSource>[
        ImageImportSource.gallery,
      ]);
      expect(
        _singleImage(editor.controller).data.sourcePath,
        'media:replacement-image',
      );
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

    await tester.tap(find.text('Pick from gallery'));
    await tester.pumpAndSettle();

    expect(imageImport.requestedSources, <ImageImportSource>[
      ImageImportSource.gallery,
    ]);
    expect(
      _singleImage(editor.controller).data.sourcePath,
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

      await tester.tap(find.text('Pick from gallery'));
      await tester.pump();

      expect(
        _singleImage(editor.controller).data.sourcePath,
        'media:existing-image',
      );
      expect(
        find.text('Failed to replace image: Upload failed'),
        findsOneWidget,
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
      final size = image.data.size as Size2D;

      expect(image.data.sourcePath, 'media:added-image');
      expect(size.w, 200);
      expect(size.h, 200);
      expect(image.xf.position.x, 180);
      expect(image.xf.position.y, 180);
      expect(editor.selection.firstId, image.id);
      expect(editor.controller.canUndo.value, isTrue);
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

  testWidgets('later Image inspector replaces image-import inspector panel', (
    tester,
  ) async {
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
    expect(find.text('Pick from gallery'), findsNothing);
    expect(find.text('Capture from camera'), findsNothing);
    expect(find.text('Width: 200'), findsNothing);
  });
}
