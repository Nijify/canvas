// Path: oss_packages/canvas_editor_flutter/test/editor_camera_controller_test.dart

import 'dart:ui' show Offset, Size;

import 'package:canvas_core/canvas_core_runtime.dart'
    show CanvasFit, CanvasViewportPlanner, Rect2D, Size2D;
import 'package:canvas_editor_flutter/src/presentation/viewport/editor_camera_controller.dart';
import 'package:canvas_editor_flutter/src/presentation/viewport/editor_camera_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditorCameraController', () {
    test('starts with the expected empty camera state', () {
      final controller = EditorCameraController();
      addTearDown(controller.dispose);

      final state = controller.value;

      expect(state.scale, 1.0);
      expect(state.pan, Offset.zero);
      expect(state.viewportW, 0);
      expect(state.viewportH, 0);
      expect(state.artboardW, 0);
      expect(state.artboardH, 0);
      expect(state.userInteracted, isFalse);
    });

    test('setPanZoom clamps scale and marks the camera as user-controlled', () {
      final controller = EditorCameraController();
      addTearDown(controller.dispose);

      controller.setPanZoom(newScale: -100, newPan: const Offset(12, -8));

      expect(controller.value.scale, kEditorCameraMinScale);
      expect(controller.value.pan, const Offset(12, -8));
      expect(controller.value.userInteracted, isTrue);

      controller.setPanZoom(newScale: 100);

      expect(controller.value.scale, kEditorCameraMaxScale);
      expect(controller.value.pan, const Offset(12, -8));
      expect(controller.value.userInteracted, isTrue);
    });

    test('setPanZoom ignores epsilon-equivalent changes', () {
      final controller = EditorCameraController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications += 1);

      controller.setPanZoom(
        newScale: 1.0 + 0.0000005,
        newPan: const Offset(0.0005, -0.0005),
      );

      expect(notifications, 0);
      expect(controller.value.scale, 1.0);
      expect(controller.value.pan, Offset.zero);
      expect(controller.value.userInteracted, isFalse);

      controller.setPanZoom(
        newScale: 1.0 + 0.000002,
        newPan: const Offset(0.002, -0.002),
      );

      expect(notifications, 1);
      expect(controller.value.userInteracted, isTrue);
    });

    test(
      'syncToLayout initially fits the artboard using CanvasViewportPlanner',
      () {
        final controller = EditorCameraController();
        addTearDown(controller.dispose);

        const viewportPx = Size(1200, 800);
        const artboard = Size2D(2000, 1000);
        const paddingPx = 40.0;

        final expected = CanvasViewportPlanner.plan(
          artboard: artboard,
          targetW: viewportPx.width,
          targetH: viewportPx.height,
          bounds: null,
          paddingPx: paddingPx,
          fit: CanvasFit.contain,
          minUniformScale: kEditorCameraMinScale,
          maxUniformScale: kEditorCameraMaxScale,
          snappingEnabled: false,
        );

        controller.syncToLayout(
          viewportPx: viewportPx,
          artboard: artboard,
          paddingPx: paddingPx,
          forceFit: false,
        );

        final state = controller.value;

        expect(state.scale, closeTo(expected.scaleX, 0.0000001));
        _expectOffsetCloseTo(
          state.pan,
          Offset(expected.translateX, expected.translateY),
        );
        expect(state.viewportW, viewportPx.width);
        expect(state.viewportH, viewportPx.height);
        expect(state.artboardW, artboard.w);
        expect(state.artboardH, artboard.h);
        expect(state.userInteracted, isFalse);
      },
    );

    test(
      'syncToLayout fits provided content bounds instead of the artboard',
      () {
        final controller = EditorCameraController();
        addTearDown(controller.dispose);

        const viewportPx = Size(1000, 700);
        const artboard = Size2D(1600, 900);
        const paddingPx = 32.0;
        final bounds = Rect2D.fromLTRB(100, 160, 700, 460);

        final expected = CanvasViewportPlanner.plan(
          artboard: const Size2D(1, 1),
          targetW: viewportPx.width,
          targetH: viewportPx.height,
          bounds: bounds,
          paddingPx: paddingPx,
          fit: CanvasFit.contain,
          minUniformScale: kEditorCameraMinScale,
          maxUniformScale: kEditorCameraMaxScale,
          snappingEnabled: false,
        );

        controller.syncToLayout(
          viewportPx: viewportPx,
          artboard: artboard,
          paddingPx: paddingPx,
          forceFit: false,
          contentBounds: bounds,
        );

        final state = controller.value;

        expect(state.scale, closeTo(expected.scaleX, 0.0000001));
        _expectOffsetCloseTo(
          state.pan,
          Offset(expected.translateX, expected.translateY),
        );
        expect(state.viewportW, viewportPx.width);
        expect(state.viewportH, viewportPx.height);
        expect(state.artboardW, artboard.w);
        expect(state.artboardH, artboard.h);
        expect(state.userInteracted, isFalse);
      },
    );

    test('forceFit refits the artboard after user interaction', () {
      final controller = EditorCameraController();
      addTearDown(controller.dispose);

      const viewportPx = Size(1000, 700);
      const artboard = Size2D(1600, 900);
      const paddingPx = 32.0;

      controller.syncToLayout(
        viewportPx: viewportPx,
        artboard: artboard,
        paddingPx: paddingPx,
        forceFit: false,
      );

      controller.setPanZoom(newScale: 1.25, newPan: const Offset(-140, 95));

      final expected = CanvasViewportPlanner.plan(
        artboard: artboard,
        targetW: viewportPx.width,
        targetH: viewportPx.height,
        bounds: null,
        paddingPx: paddingPx,
        fit: CanvasFit.contain,
        minUniformScale: kEditorCameraMinScale,
        maxUniformScale: kEditorCameraMaxScale,
        snappingEnabled: false,
      );

      controller.syncToLayout(
        viewportPx: viewportPx,
        artboard: artboard,
        paddingPx: paddingPx,
        forceFit: true,
      );

      final state = controller.value;

      expect(state.scale, closeTo(expected.scaleX, 0.0000001));
      _expectOffsetCloseTo(
        state.pan,
        Offset(expected.translateX, expected.translateY),
      );

      // Forced artboard fitting restores the camera transform but does not
      // clear the user's interaction marker.
      expect(state.userInteracted, isTrue);
    });

    test('forceFit content-bounds framing resets user interaction', () {
      final controller = EditorCameraController();
      addTearDown(controller.dispose);

      const viewportPx = Size(1000, 700);
      const artboard = Size2D(1600, 900);
      const paddingPx = 32.0;

      final bounds = Rect2D.fromLTRB(100, 160, 700, 460);

      controller.syncToLayout(
        viewportPx: viewportPx,
        artboard: artboard,
        paddingPx: paddingPx,
        forceFit: false,
        contentBounds: bounds,
      );

      controller.setPanZoom(newScale: 1.25, newPan: const Offset(-140, 95));

      expect(controller.value.userInteracted, isTrue);

      final expected = CanvasViewportPlanner.plan(
        artboard: const Size2D(1, 1),
        targetW: viewportPx.width,
        targetH: viewportPx.height,
        bounds: bounds,
        paddingPx: paddingPx,
        fit: CanvasFit.contain,
        minUniformScale: kEditorCameraMinScale,
        maxUniformScale: kEditorCameraMaxScale,
        snappingEnabled: false,
      );

      controller.syncToLayout(
        viewportPx: viewportPx,
        artboard: artboard,
        paddingPx: paddingPx,
        forceFit: true,
        contentBounds: bounds,
      );

      final state = controller.value;

      expect(state.scale, closeTo(expected.scaleX, 0.0000001));

      _expectOffsetCloseTo(
        state.pan,
        Offset(expected.translateX, expected.translateY),
      );

      // This preserves the current focused-editor behavior:
      // a forced content-bounds fit clears the user-controlled camera marker.
      expect(state.userInteracted, isFalse);
    });

    test(
      'preserves the world point at viewport centre after user interaction',
      () {
        final controller = EditorCameraController();
        addTearDown(controller.dispose);

        const initialViewportPx = Size(1000, 600);
        const resizedViewportPx = Size(1300, 800);
        const artboard = Size2D(1600, 900);
        const paddingPx = 24.0;

        controller.syncToLayout(
          viewportPx: initialViewportPx,
          artboard: artboard,
          paddingPx: paddingPx,
          forceFit: false,
        );

        const userScale = 0.8;
        const userPan = Offset(-110, 75);

        controller.setPanZoom(newScale: userScale, newPan: userPan);

        final oldCentre = Offset(
          initialViewportPx.width / 2,
          initialViewportPx.height / 2,
        );

        final worldAtOldCentre = (oldCentre - userPan) / userScale;

        final newCentre = Offset(
          resizedViewportPx.width / 2,
          resizedViewportPx.height / 2,
        );

        final expectedPan = newCentre - worldAtOldCentre * userScale;

        controller.syncToLayout(
          viewportPx: resizedViewportPx,
          artboard: artboard,
          paddingPx: paddingPx,
          forceFit: false,
        );

        final state = controller.value;

        expect(state.scale, userScale);
        _expectOffsetCloseTo(state.pan, expectedPan);
        expect(state.viewportW, resizedViewportPx.width);
        expect(state.viewportH, resizedViewportPx.height);
        expect(state.artboardW, artboard.w);
        expect(state.artboardH, artboard.h);
        expect(state.userInteracted, isTrue);
      },
    );

    test('ignores invalid layout measurements', () {
      final controller = EditorCameraController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications += 1);

      controller.syncToLayout(
        viewportPx: Size.zero,
        artboard: const Size2D(100, 100),
        paddingPx: 24,
        forceFit: false,
      );

      controller.syncToLayout(
        viewportPx: const Size(300, 200),
        artboard: const Size2D(0, 100),
        paddingPx: 24,
        forceFit: false,
      );

      expect(notifications, 0);
      expect(controller.value, const EditorCameraState.initial());
    });
  });
}

void _expectOffsetCloseTo(
  Offset actual,
  Offset expected, {
  double precision = 0.0000001,
}) {
  expect(actual.dx, closeTo(expected.dx, precision));
  expect(actual.dy, closeTo(expected.dy, precision));
}
