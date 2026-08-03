// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/widgets/canvas_viewport_surface.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart'
    show EditorController;
import 'package:canvas_editor_flutter/src/editor_hosts.dart'
    show EditorSelectionHost;
import 'package:canvas_editor_flutter/src/editor_surface_features.dart'
    show SelectionChromeMode;
import 'package:canvas_editor_flutter/src/interaction/canvas_viewport_behavior.dart';
import 'package:canvas_editor_flutter/src/interaction/editor_interaction_policy.dart';
import 'package:canvas_editor_flutter/src/presentation/viewport/editor_camera_controller.dart';
import 'package:canvas_editor_flutter/src/presentation/viewport/editor_camera_state.dart';
import 'package:canvas_editor_flutter/src/presentation/widgets/canvas_viewport.dart';
import 'package:canvas_editor_flutter/src/presentation/widgets/selection_overlay.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter/material.dart';

/// Canvas viewport plus editor interaction overlays.
class CanvasViewportSurface extends StatelessWidget {
  const CanvasViewportSurface({
    super.key,
    required this.selectionChromeMode,
    required this.snap,
    required this.camera,
    required this.renderer,
    required this.repaint,
    required this.controller,
    required this.selection,
    required this.onViewportPx,
    required this.cameraReady,
    required this.interactionPolicy,
    required this.viewportBehavior,
  });

  final SelectionChromeMode selectionChromeMode;
  final RenderSnapshot snap;
  final EditorCameraController camera;

  final CanvasRenderer renderer;
  final Listenable repaint;

  final EditorController controller;
  final EditorSelectionHost selection;

  final ValueChanged<Size> onViewportPx;

  /// Whether the canvas may paint using the current camera state.
  ///
  /// This is normally true. Hosted content-bounds editors can hold it false
  /// until the first measured-viewport camera fit has been applied.
  final bool cameraReady;

  final EditorInteractionPolicy interactionPolicy;
  final CanvasViewportBehavior? viewportBehavior;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportPx = constraints.biggest;

        if (viewportPx.width.isFinite &&
            viewportPx.height.isFinite &&
            viewportPx.width > 0 &&
            viewportPx.height > 0) {
          onViewportPx(viewportPx);
        }

        if (!cameraReady) {
          return const ColoredBox(
            color: Color(0xFFF6F7FB),
            child: SizedBox.expand(),
          );
        }

        return ValueListenableBuilder<EditorCameraState>(
          valueListenable: camera,
          builder: (context, cameraState, _) {
            return Stack(
              children: [
                CanvasViewport(
                  render: snap,
                  renderer: renderer,
                  viewportPx: viewportPx,
                  scale: cameraState.scale,
                  pan: cameraState.pan,
                  onPanZoom: (scale, pan) =>
                      camera.setPanZoom(newScale: scale, newPan: pan),
                  repaint: repaint,
                  selection: selection,
                  controller: controller,
                  interactionPolicy: interactionPolicy,
                  viewportBehavior: viewportBehavior,
                ),
                if (selectionChromeMode ==
                    SelectionChromeMode.transformControls)
                  ValueListenableBuilder(
                    valueListenable: selection,
                    builder: (_, selectionState, _) {
                      final selectedIds = selectionState.hasItems
                          ? selectionState.ids
                          : const <String>{};

                      final sourceScene = controller.document.value;

                      final chromeSelectedIds = selectedIds.where((id) {
                        final node =
                            findById(sourceScene, id) ??
                            findById(snap.scene, id);

                        return node != null &&
                            interactionPolicy.showTransformChrome(node);
                      }).toSet();

                      if (chromeSelectedIds.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return CanvasSelectionOverlay(
                        render: snap,
                        scale: cameraState.scale,
                        pan: cameraState.pan,
                        selectedIds: chromeSelectedIds,
                      );
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
