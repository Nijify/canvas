// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/widgets/canvas_editor_scaffold_layout.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart'
    show EditorController;
import 'package:canvas_editor_flutter/src/editor_surface_features.dart'
    show SelectionChromeMode;
import 'package:canvas_editor_flutter/src/editor_shell_config.dart';
import 'package:canvas_editor_flutter/src/interaction/canvas_viewport_behavior.dart';
import 'package:canvas_editor_flutter/src/interaction/editor_interaction_policy.dart';
import 'package:canvas_editor_flutter/src/canvas_runtime_resources.dart'
    show CanvasRuntimeResources;
import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart';
import 'package:canvas_editor_flutter/src/presentation/viewport/editor_camera_controller.dart';
import 'package:canvas_editor_flutter/src/presentation/layers/scene_object_tree.dart'
    show SceneObjectPresentationPolicy;
import 'package:canvas_editor_flutter/src/presentation/widgets/canvas_viewport_surface.dart';
import 'package:canvas_editor_flutter/src/presentation/actions/editor_actions.dart';
import 'package:canvas_editor_flutter/src/presentation/widgets/editor_app_bar.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_context.dart'
    show InspectorBuilder, InspectorFieldRowBuilder;
import 'package:canvas_editor_flutter/src/presentation/layers/layers_panel.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Presentation layout for the editor surface.
///
/// This file only arranges canvas, inspector, layers, and optional shell chrome.
/// It must not own document persistence or app-specific workflows.
class CanvasEditorScaffoldLayout extends StatelessWidget {
  const CanvasEditorScaffoldLayout({
    super.key,
    required this.shell,
    required this.camera,
    required this.onViewportPx,
    required this.cameraReady,
    required this.selectionChromeMode,
    required this.resources,
    required this.toolbarState,
    required this.actions,
    required this.actionSpecs,
    required this.renderer,
    required this.repaint,
    required this.appBarBuilder,
    required this.inspectorBuilder,
    required this.interactionPolicy,
    required this.viewportBehavior,
    required this.sceneObjectPolicy,
    this.inspectorFieldRowBuilder,
  });

  final EditorShellConfig shell;
  final EditorCameraController camera;

  final SelectionChromeMode selectionChromeMode;
  final CanvasRuntimeResources resources;
  final EditorToolbarState toolbarState;
  final EditorActionDispatcher actions;
  final List<EditorActionSpec> actionSpecs;

  final CanvasRenderer renderer;
  final Listenable repaint;

  final ValueChanged<Size> onViewportPx;
  final bool cameraReady;

  final EditorAppBarBuilder? appBarBuilder;
  final InspectorBuilder? inspectorBuilder;
  final EditorInteractionPolicy interactionPolicy;
  final CanvasViewportBehavior? viewportBehavior;
  final SceneObjectPresentationPolicy sceneObjectPolicy;
  final InspectorFieldRowBuilder? inspectorFieldRowBuilder;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<EditorController>();

    Widget buildLayersPanel(BuildContext context) {
      return LayersPanel(
        controller: controller,
        selection: context.read<SelectionController>(),
        policy: sceneObjectPolicy,
      );
    }

    Widget buildCanvasOnly(BuildContext context, RenderSnapshot snap) {
      final selection = context.read<SelectionController>();

      return CanvasViewportSurface(
        camera: camera,
        selectionChromeMode: selectionChromeMode,
        snap: snap,
        renderer: renderer,
        repaint: repaint,
        controller: controller,
        selection: selection,
        onViewportPx: onViewportPx,
        cameraReady: cameraReady,
        interactionPolicy: interactionPolicy,
        viewportBehavior: viewportBehavior,
      );
    }

    Widget buildDockedInspectorLayout(
      BuildContext context,
      RenderSnapshot snap,
    ) {
      final selection = context.read<SelectionController>();

      final canvas = CanvasViewportSurface(
        selectionChromeMode: selectionChromeMode,
        snap: snap,
        camera: camera,
        renderer: renderer,
        repaint: repaint,
        controller: controller,
        selection: selection,
        onViewportPx: onViewportPx,
        cameraReady: cameraReady,
        interactionPolicy: interactionPolicy,
        viewportBehavior: viewportBehavior,
      );

      final inspector = Inspector(
        renderSnapshot: snap,
        controller: controller,
        selection: selection,
        resources: resources,
        builder: inspectorBuilder,
        fieldRowBuilder: inspectorFieldRowBuilder,
      );

      final wide = !shell.hosted && MediaQuery.of(context).size.width >= 900;

      if (wide) {
        final showLayers = shell.showLayersPanel;

        return Row(
          children: [
            if (showLayers)
              SizedBox(width: 260, child: buildLayersPanel(context)),
            Expanded(child: canvas),
            SizedBox(width: 320, child: inspector),
          ],
        );
      }

      return Column(
        children: [
          Expanded(flex: 3, child: canvas),
          const Divider(height: 1),
          SizedBox(
            height: 320,
            child: Column(children: [Expanded(child: inspector)]),
          ),
        ],
      );
    }

    Widget buildCompactHostedInspectorPanel(
      BuildContext context,
      RenderSnapshot snap,
    ) {
      final selection = context.read<SelectionController>();

      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: Inspector(
          renderSnapshot: snap,
          controller: controller,
          selection: selection,
          resources: resources,
          builder: inspectorBuilder,
          compact: true,
          fieldRowBuilder: inspectorFieldRowBuilder,
        ),
      );
    }

    return ValueListenableBuilder<RenderSnapshot>(
      valueListenable: controller.render,
      builder: (context, snap, _) {
        if (shell.hosted) {
          final header = shell.hostedHeaderBuilder?.call(
            context,
            toolbarState,
            actions,
            actionSpecs,
          );

          Widget? bottomChild = shell.hostedBottomBuilder?.call(
            context,
            toolbarState,
            actions,
            actionSpecs,
          );

          if (bottomChild == null &&
              shell.inspectorPresentation ==
                  InspectorPresentation.inlineCompact) {
            bottomChild = buildCompactHostedInspectorPanel(context, snap);
          }

          final bottomH =
              shell.hostedBottomHeight ??
              (MediaQuery.of(context).size.height * 0.22).clamp(160.0, 220.0);

          return Column(
            children: [
              ?header,
              Expanded(child: buildCanvasOnly(context, snap)),
              if (bottomChild != null) ...[
                const Divider(height: 1),
                SizedBox(height: bottomH, child: bottomChild),
              ],
            ],
          );
        }

        final body = shell.inspectorPresentation == InspectorPresentation.docked
            ? buildDockedInspectorLayout(context, snap)
            : buildCanvasOnly(context, snap);

        return Scaffold(
          appBar: shell.showDefaultAppBar
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child:
                      appBarBuilder?.call(
                        context,
                        toolbarState,
                        actions,
                        actionSpecs,
                      ) ??
                      EditorAppBar(
                        title: 'Canvas Editor',
                        state: toolbarState,
                        actions: actions,
                        actionSpecs: actionSpecs,
                      ),
                )
              : null,
          body: body,
        );
      },
    );
  }
}
