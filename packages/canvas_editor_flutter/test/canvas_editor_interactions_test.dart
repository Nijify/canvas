// Path: oss_packages/canvas_editor_flutter/test/canvas_editor_interactions_test.dart
import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/canvas_editor_flutter.dart';
import 'package:canvas_editor_flutter/src/presentation/viewport/editor_camera_controller.dart';
import 'package:canvas_editor_flutter/src/presentation/viewport/editor_camera_state.dart'
    show kEditorCameraMaxScale, kEditorCameraMinScale;
import 'package:canvas_editor_flutter/src/editor_api.dart';
import 'package:canvas_editor_flutter/src/editor_edits.dart';
import 'package:canvas_editor_flutter/src/editor_extensions.dart';
import 'package:canvas_editor_flutter/src/editor_surface_features.dart';
import 'package:canvas_editor_flutter/src/interaction/canvas_viewport_behavior.dart';
import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart';
import 'package:canvas_editor_flutter/src/presentation/widgets/canvas_viewport.dart';
import 'package:canvas_editor_flutter/src/presentation/widgets/canvas_viewport_surface.dart';
import 'package:canvas_editor_flutter/src/presentation/widgets/editor_app_bar.dart';

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

final class _ForceShapeMoveBehavior extends CanvasViewportBehavior {
  const _ForceShapeMoveBehavior();

  @override
  CanvasDragStartIntent? resolveDragStartSelection(
    BuildContext context,
    CanvasViewportBehaviorContext ctx,
    CanvasHitTestResult hit,
    ScaleStartDetails details,
  ) {
    if (details.pointerCount != 1) {
      return const CanvasDragStartIntent.noMove();
    }

    return const CanvasDragStartIntent.move('shape-1');
  }
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

Future<
  ({
    EditorController controller,
    EditorCameraController camera,
    SelectionController selection,
  })
>
_pumpResizableEditor(
  WidgetTester tester, {
  required ValueNotifier<Size> hostSize,
  CanvasSceneDocument? initialScene,
  List<EditorExtension<CanvasSceneDocument>> extensions = const [],
}) async {
  final scene = initialScene ?? _fixtureScene();

  await tester.pumpWidget(
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: ValueListenableBuilder<Size>(
          valueListenable: hostSize,
          builder: (context, size, _) {
            return SizedBox(
              width: size.width,
              height: size.height,
              child: CanvasSceneEditor(
                initialScene: scene,
                resources: canvasRuntimeResourcesForTest(),
                extensions: extensions,
              ),
            );
          },
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
        .layoutBoundsWorldById['shape-1']!;

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
            appearance: CanvasAppearance(
              foreground: CanvasFill.solid(0xFF111111),
            ),
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
        .layoutBoundsWorldById['shape-1']!;

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
        .layoutBoundsWorldById['shape-1']!;

    expect(boundsAfter.width, greaterThan(boundsBefore.width));
  });

  testWidgets('canvas viewport fills its measured layout slot', (tester) async {
    final hostSize = ValueNotifier<Size>(const Size(1400, 900));
    addTearDown(hostSize.dispose);

    final editor = await _pumpResizableEditor(tester, hostSize: hostSize);

    final viewportFinder = find.byType(CanvasViewport).first;

    final viewport = tester.widget<CanvasViewport>(viewportFinder);
    final renderBox = tester.renderObject<RenderBox>(viewportFinder);

    // Camera planning and the actual interactive viewport must use the same
    // rectangle.
    expect(renderBox.size.width, closeTo(viewport.viewportPx.width, 0.001));
    expect(renderBox.size.height, closeTo(viewport.viewportPx.height, 0.001));

    // Initial fitting must center the artboard within the real viewport.
    final camera = editor.camera.value;
    final artboard = editor.controller.render.value.scene.artboardSize;

    final artboardCenterOnScreen = Offset(
      artboard.w * 0.5 * camera.scale + camera.pan.dx,
      artboard.h * 0.5 * camera.scale + camera.pan.dy,
    );

    final actualViewportCenter = Offset(
      renderBox.size.width * 0.5,
      renderBox.size.height * 0.5,
    );

    _expectOffsetCloseTo(artboardCenterOnScreen, actualViewportCenter);
  });

  testWidgets('viewport resize refits before camera interaction', (
    tester,
  ) async {
    final hostSize = ValueNotifier<Size>(const Size(1400, 900));
    addTearDown(hostSize.dispose);

    final editor = await _pumpResizableEditor(tester, hostSize: hostSize);

    expect(editor.camera.value.userInteracted, isFalse);

    hostSize.value = const Size(1300, 820);
    await tester.pumpAndSettle();

    final viewport = tester.widget<CanvasViewport>(
      find.byType(CanvasViewport).first,
    );

    final expected = CanvasViewportPlanner.plan(
      artboard: _fixtureScene().artboardSize,
      targetW: viewport.viewportPx.width,
      targetH: viewport.viewportPx.height,
      bounds: null,
      paddingPx: 24.0,
      fit: CanvasFit.contain,
      minUniformScale: kEditorCameraMinScale,
      maxUniformScale: kEditorCameraMaxScale,
      snappingEnabled: false,
    );

    expect(editor.camera.value.userInteracted, isFalse);
    expect(editor.camera.value.scale, closeTo(expected.scaleX, 0.0000001));
    _expectOffsetCloseTo(
      editor.camera.value.pan,
      Offset(expected.translateX, expected.translateY),
    );

    expect(editor.camera.value.viewportW, viewport.viewportPx.width);
    expect(editor.camera.value.viewportH, viewport.viewportPx.height);
  });

  testWidgets(
    'viewport resize preserves viewed center after camera interaction',
    (tester) async {
      final hostSize = ValueNotifier<Size>(const Size(1400, 900));
      addTearDown(hostSize.dispose);

      final editor = await _pumpResizableEditor(tester, hostSize: hostSize);

      final initialViewport = tester.widget<CanvasViewport>(
        find.byType(CanvasViewport).first,
      );

      const userScale = 1.25;
      const userPan = Offset(-110, 75);

      editor.camera.setPanZoom(newScale: userScale, newPan: userPan);

      await tester.pump();

      final oldCenter = Offset(
        initialViewport.viewportPx.width / 2,
        initialViewport.viewportPx.height / 2,
      );

      final worldAtOldCenter = (oldCenter - userPan) / userScale;

      hostSize.value = const Size(1300, 820);
      await tester.pumpAndSettle();

      final resizedViewport = tester.widget<CanvasViewport>(
        find.byType(CanvasViewport).first,
      );

      final newCenter = Offset(
        resizedViewport.viewportPx.width / 2,
        resizedViewport.viewportPx.height / 2,
      );

      final expectedPan = newCenter - worldAtOldCenter * userScale;

      expect(editor.camera.value.userInteracted, isTrue);
      expect(editor.camera.value.scale, userScale);

      _expectOffsetCloseTo(editor.camera.value.pan, expectedPan);
    },
  );

  testWidgets(
    'artboard size change resynchronizes camera without viewport resize',
    (tester) async {
      final hostSize = ValueNotifier<Size>(const Size(1400, 900));
      addTearDown(hostSize.dispose);

      final editor = await _pumpResizableEditor(tester, hostSize: hostSize);

      const nextArtboard = Size2D(600, 400);

      editor.controller.applyEdit(
        (scene) =>
            EditorEditResult(scene: scene.copyWith(artboardSize: nextArtboard)),
      );

      await tester.pumpAndSettle();

      final viewport = tester.widget<CanvasViewport>(
        find.byType(CanvasViewport).first,
      );

      final expected = CanvasViewportPlanner.plan(
        artboard: nextArtboard,
        targetW: viewport.viewportPx.width,
        targetH: viewport.viewportPx.height,
        bounds: null,
        paddingPx: 24.0,
        fit: CanvasFit.contain,
        minUniformScale: kEditorCameraMinScale,
        maxUniformScale: kEditorCameraMaxScale,
        snappingEnabled: false,
      );

      expect(editor.camera.value.artboardW, nextArtboard.w);
      expect(editor.camera.value.artboardH, nextArtboard.h);

      expect(editor.camera.value.scale, closeTo(expected.scaleX, 0.0000001));

      _expectOffsetCloseTo(
        editor.camera.value.pan,
        Offset(expected.translateX, expected.translateY),
      );
    },
  );

  testWidgets('local editor width controls toolbar and docked layout', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1600, 1000);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final hostSize = ValueNotifier<Size>(const Size(480, 700));
    addTearDown(hostSize.dispose);

    await _pumpResizableEditor(tester, hostSize: hostSize);

    // The outer browser/test view is wide, but the editor itself is narrow.
    var appBar = tester.widget<EditorAppBar>(find.byType(EditorAppBar));

    expect(appBar.state.compact, isTrue);

    var viewport = tester.widget<CanvasViewport>(
      find.byType(CanvasViewport).first,
    );

    // Narrow layout gives the canvas the full editor width.
    expect(viewport.viewportPx.width, closeTo(480.0, 0.001));

    hostSize.value = const Size(1200, 700);
    await tester.pumpAndSettle();

    appBar = tester.widget<EditorAppBar>(find.byType(EditorAppBar));

    expect(appBar.state.compact, isFalse);

    viewport = tester.widget<CanvasViewport>(find.byType(CanvasViewport).first);

    // Wide standalone layout:
    // 1200 - 320 layers - 320 inspector = 560 canvas.
    expect(viewport.viewportPx.width, closeTo(560.0, 0.001));
  });

  testWidgets(
    'viewport resize during object drag does not move the document spuriously',
    (tester) async {
      final hostSize = ValueNotifier<Size>(const Size(1400, 900));
      addTearDown(hostSize.dispose);

      final editor = await _pumpResizableEditor(
        tester,
        hostSize: hostSize,
        extensions: const [
          StaticEditorExtension<CanvasSceneDocument>(
            surfaceFeatures: EditorSurfaceFeatures(
              viewportBehavior: _ForceShapeMoveBehavior(),
            ),
          ),
        ],
      );

      final viewportBox = tester.renderObject<RenderBox>(
        find.byType(CanvasViewport).first,
      );

      final gesture = await tester.startGesture(
        viewportBox.localToGlobal(
          Offset(viewportBox.size.width / 2, viewportBox.size.height / 2),
        ),
      );

      await tester.pump();

      final beforeDrag = findById(
        editor.controller.document.value,
        'shape-1',
      )!.xf.position;

      // First movement lets Flutter's scale recognizer establish the gesture.
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();

      // This update must run through the active object-move path.
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();

      final afterFirstMove = findById(
        editor.controller.document.value,
        'shape-1',
      )!.xf.position;

      expect(afterFirstMove, isNot(beforeDrag));

      // Resize while the pointer is still down.
      hostSize.value = const Size(1300, 820);
      await tester.pumpAndSettle();

      final afterResize = findById(
        editor.controller.document.value,
        'shape-1',
      )!.xf.position;

      // Layout/camera synchronization itself must never move the document.
      expect(afterResize, afterFirstMove);

      // Use a tiny post-resize pointer movement. A correctly rebased/screen-space
      // drag should produce only a tiny world-space movement. The old implementation
      // produces a large jump because the camera transform changed underneath the
      // stored canvas-space anchor.
      await gesture.moveBy(const Offset(1, 0));
      await tester.pump();

      final afterFurtherPointerMove = findById(
        editor.controller.document.value,
        'shape-1',
      )!.xf.position;

      final postResizeDelta = afterFurtherPointerMove - afterResize;

      expect(postResizeDelta.x.abs(), lessThan(5.0));
      expect(postResizeDelta.y.abs(), lessThan(5.0));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

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
              appearance: CanvasAppearance(
                foreground: CanvasFill.solid(0xFF111111),
              ),
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
