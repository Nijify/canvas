// Path: oss_packages/canvas_editor_flutter/test/canvas_editor_interactions_test.dart
import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/canvas_editor_flutter.dart';
import 'package:canvas_editor_flutter/src/presentation/viewport/editor_camera_controller.dart';
import 'package:canvas_editor_flutter/src/presentation/viewport/editor_camera_state.dart'
    show kEditorCameraMaxScale, kEditorCameraMinScale;
import 'package:canvas_editor_flutter/src/editor_api.dart';
import 'package:canvas_editor_flutter/src/editor_edits.dart';
import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart';
import 'package:canvas_editor_flutter/src/presentation/widgets/canvas_viewport.dart';
import 'package:canvas_editor_flutter/src/presentation/widgets/canvas_viewport_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'editor_runtime_fakes.dart';

CanvasSceneDocument _fixtureScene() {
  return CanvasSceneDocument(
    artboardSize: const Size2D(300, 200),
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: const <Node>[
      Node.path(
        id: 'shape-1',
        xf: Transform2D(
          position: Vec2(40, 40),
          origin: OriginKind.custom,
          customPivotPx: Vec2(40, 30),
        ),
        data: PathData(
          points: <Vec2?>[],
          source: RectSource(80, 60),
          fill: CanvasFill.solid(0xFF22C55E),
          strokeColor: 0xFF111111,
          strokeWidth: 2,
        ),
      ),
    ],
  );
}

Future<
  ({
    EditorController controller,
    EditorCameraController camera,
    SelectionController selection,
  })
>
_pumpEditor(
  WidgetTester tester, {
  ValueChanged<CanvasSceneDocument>? onSceneChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox.expand(
        child: CanvasSceneEditor(
          initialScene: _fixtureScene(),
          resources: canvasRuntimeResourcesForTest(),
          onSceneChanged: onSceneChanged,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();

  final context = tester.element(find.byType(Scaffold).first);

  final viewportSurface = tester.widget<CanvasViewportSurface>(
    find.byType(CanvasViewportSurface).first,
  );

  return (
    controller: context.read<EditorController>(),
    camera: viewportSurface.camera,
    selection: Provider.of<SelectionController>(context, listen: false),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tap selects an element and empty canvas clears selection', (
    tester,
  ) async {
    final editor = await _pumpEditor(tester);
    editor.camera.setPanZoom(newScale: 1.0, newPan: Offset.zero);
    await tester.pumpAndSettle();

    final bounds = editor
        .controller
        .render
        .value
        .computed
        .visualBoundsWorldById['shape-1']!;

    final center = Vec2(
      (bounds.left + bounds.right) / 2,
      (bounds.top + bounds.bottom) / 2,
    );

    final viewportBox = tester.renderObject<RenderBox>(
      find.byType(CanvasViewport),
    );

    final shapeCenterInViewport = Offset(center.x, center.y);

    expect(viewportBox.size.contains(shapeCenterInViewport), isTrue);

    await tester.tapAt(viewportBox.localToGlobal(shapeCenterInViewport));
    await tester.pump();

    expect(editor.selection.value.ids, contains('shape-1'));

    await tester.tapAt(viewportBox.localToGlobal(const Offset(280, 180)));
    await tester.pump();

    expect(editor.selection.value.isEmpty, isTrue);
  });

  testWidgets('keyboard shortcuts route to undo and redo', (tester) async {
    final editor = await _pumpEditor(tester);

    editor.controller.applyEdit(
      EditorEdits.addNode(
        const Node.text(
          id: 'text-2',
          xf: Transform2D(position: Vec2(10, 10)),
          data: TextData(
            text: 'Undo me',
            fontFamily: 'TestFont',
            fontWeight: 400,
            fontSize: 14,
            letterSpacing: 0,
            fill: CanvasFill.solid(0xFF111111),
            shadowOffset: 0,
          ),
        ),
      ),
    );

    expect(editor.controller.canUndo.value, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(editor.controller.canRedo.value, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(editor.controller.canUndo.value, isTrue);
  });

  testWidgets('resize updates rendered element bounds', (tester) async {
    final editor = await _pumpEditor(tester);

    final boundsBefore = editor
        .controller
        .render
        .value
        .computed
        .visualBoundsWorldById['shape-1']!;

    final nodeBefore = findById(editor.controller.document.value, 'shape-1')!;
    final endSession = editor.controller.beginEditSession();

    try {
      editor.controller.updateUniformScaleAround(
        'shape-1',
        nodeBefore.xf.position,
        1.25,
      );
    } finally {
      endSession();
    }

    await tester.pumpAndSettle();

    final boundsAfter = editor
        .controller
        .render
        .value
        .computed
        .visualBoundsWorldById['shape-1']!;

    expect(boundsAfter.width, greaterThan(boundsBefore.width));
  });

  testWidgets('first CanvasViewport build receives the fitted camera state', (
    tester,
  ) async {
    final scene = _fixtureScene();

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: CanvasSceneEditor(
            initialScene: scene,
            resources: canvasRuntimeResourcesForTest(),
          ),
        ),
      ),
    );

    // Deliberately do not call pumpAndSettle().
    //
    // This checks the first rendered editor frame: LayoutBuilder reports the
    // viewport size, CanvasEditorSurface synchronizes the camera immediately,
    // and CanvasViewport must receive that fitted state in the same frame.
    final viewportSurface = tester.widget<CanvasViewportSurface>(
      find.byType(CanvasViewportSurface).first,
    );

    final camera = viewportSurface.camera;

    final viewport = tester.widget<CanvasViewport>(
      find.byType(CanvasViewport).first,
    );

    final expected = CanvasViewportPlanner.plan(
      artboard: scene.artboardSize,
      targetW: viewport.viewportPx.width,
      targetH: viewport.viewportPx.height,
      bounds: null,
      paddingPx: 24.0,
      fit: CanvasFit.contain,
      minUniformScale: kEditorCameraMinScale,
      maxUniformScale: kEditorCameraMaxScale,
      snappingEnabled: false,
    );

    expect(camera.value.viewportW, viewport.viewportPx.width);
    expect(camera.value.viewportH, viewport.viewportPx.height);
    expect(camera.value.artboardW, scene.artboardSize.w);
    expect(camera.value.artboardH, scene.artboardSize.h);
    expect(camera.value.userInteracted, isFalse);

    expect(camera.value.scale, closeTo(expected.scaleX, 0.0000001));
    _expectOffsetCloseTo(
      camera.value.pan,
      Offset(expected.translateX, expected.translateY),
    );

    // The actual first CanvasViewport widget must receive precisely the same
    // already-fitted transform as the controller.
    expect(viewport.scale, closeTo(camera.value.scale, 0.0000001));
    _expectOffsetCloseTo(viewport.pan, camera.value.pan);
  });

  testWidgets(
    'CanvasSceneEditor emits the edited base scene as CanvasSceneDocument',
    (tester) async {
      final emittedScenes = <CanvasSceneDocument>[];

      final editor = await _pumpEditor(
        tester,
        onSceneChanged: emittedScenes.add,
      );

      // Ignore any lifecycle work completed while the editor was first pumped.
      // The assertion below is only about the explicit edit made in this test.
      emittedScenes.clear();

      editor.controller.applyEdit(
        EditorEdits.addNode(
          const Node.text(
            id: 'callback-text',
            xf: Transform2D(position: Vec2(10, 10)),
            data: TextData(
              text: 'Callback test',
              fontFamily: 'TestFont',
              fontWeight: 400,
              fontSize: 14,
              letterSpacing: 0,
              fill: CanvasFill.solid(0xFF111111),
              shadowOffset: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(emittedScenes, hasLength(1));

      final emittedScene = emittedScenes.single;
      final currentBaseScene = editor.controller.document.value;

      expect(emittedScene, isA<CanvasSceneDocument>());
      expect(
        emittedScene.children.map((node) => node.id),
        containsAll(<String>['shape-1', 'callback-text']),
      );

      // The callback must emit the editable/base scene, not a render snapshot
      // and not serialized JSON.
      expect(emittedScene, currentBaseScene);
    },
  );
}

void _expectOffsetCloseTo(
  Offset actual,
  Offset expected, {
  double precision = 0.0000001,
}) {
  expect(actual.dx, closeTo(expected.dx, precision));
  expect(actual.dy, closeTo(expected.dy, precision));
}
