// Path: oss_packages/canvas_editor_flutter/example/test/example_app_smoke_test.dart

import 'package:canvas_editor_flutter/canvas_editor_flutter.dart'
    show CanvasSceneEditor;
import 'package:canvas_editor_flutter_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'example launches through optional asset-library and image-import integrations',
    (tester) async {
      await tester.pumpWidget(const CanvasEditorExampleApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CanvasSceneEditor), findsOneWidget);
    },
  );
}
