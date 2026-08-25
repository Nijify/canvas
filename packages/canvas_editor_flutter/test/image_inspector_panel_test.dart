// Path: oss_packages/canvas_editor_flutter/test/image_inspector_panel_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/canvas_editor_flutter.dart';
import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector.dart'
    show ImageGeometryInspectorControls;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'editor_runtime_fakes.dart';

const _imageId = 'image-1';
const _assetId = 'asset-1';

CanvasSceneDocument _fixtureScene() {
  return const CanvasSceneDocument(
    artboardSize: Size2D(300, 200),
    backgroundFill: CanvasFill.none(),
    backgroundOpacity: 1.0,
    assets: <CanvasAssetId, CanvasImageAsset>{
      _assetId: CanvasImageAsset(sourceRef: 'media:test-image'),
    },
    children: <Node>[
      Node.image(
        id: _imageId,
        data: ImageData(assetId: _assetId, size: Size2D(200, 160)),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'base image inspector exposes geometry without image acquisition controls',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.expand(
            child: CanvasSceneEditor(
              initialScene: _fixtureScene(),
              resources: canvasRuntimeResourcesForTest(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldContext = tester.element(find.byType(Scaffold).first);
      final selection = Provider.of<SelectionController>(
        scaffoldContext,
        listen: false,
      );

      selection.selectItems(const <String>[_imageId]);
      await tester.pumpAndSettle();

      expect(find.text('Image'), findsOneWidget);

      expect(find.text('Pick from gallery'), findsNothing);
      expect(find.text('Capture from camera'), findsNothing);

      expect(find.byType(ImageGeometryInspectorControls), findsOneWidget);
      expect(find.text('Width: 200'), findsOneWidget);
      expect(find.text('Height: 160'), findsOneWidget);
    },
  );
}
