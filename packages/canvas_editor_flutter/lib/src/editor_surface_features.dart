// Path: oss_packages/canvas_editor_flutter/lib/src/editor_surface_features.dart

import 'package:canvas_core/canvas_core_runtime.dart' show ContentBoundsSpec;
import 'package:canvas_editor_flutter/src/interaction/canvas_viewport_behavior.dart'
    show CanvasViewportBehavior;
import 'package:canvas_editor_flutter/src/interaction/editor_interaction_policy.dart'
    show EditorInteractionPolicy;
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_context.dart'
    show InspectorBuilder, InspectorSectionBuilder;
import 'package:canvas_editor_flutter/src/presentation/layers/scene_object_tree.dart'
    show SceneObjectPresentationPolicy;
import 'package:flutter/foundation.dart';

InspectorBuilder? _composeInspectorBuilders(
  InspectorBuilder? earlier,
  InspectorBuilder? later,
) {
  if (later == null) return earlier;
  if (earlier == null) return later;

  return (context) => later(context) ?? earlier(context);
}

/// Controls the editor chrome drawn around the selected object.
///
/// This affects presentation only; it does not change selection or permissions.
enum SelectionChromeMode {
  /// No selection box, resize handles, or rotate handle.
  hidden,

  /// Selection frame with resize and rotate controls.
  transformControls,
}

/// Live-editor viewport framing configuration.
///
/// Preview thumbnails and final exports should pass their own render/crop
/// configuration instead of reusing live editor surface configuration.
@immutable
class EditorViewportFraming {
  const EditorViewportFraming.artboard({this.paddingPx = 24.0})
    : contentBoundsSpec = null;

  const EditorViewportFraming.contentBounds({
    this.paddingPx = 0.0,
    this.contentBoundsSpec = const ContentBoundsSpec(paddingPx: 24.0),
  });

  /// Padding applied by the viewport planner while fitting the framing target.
  final double paddingPx;

  /// Configuration used to derive rendered content bounds.
  ///
  /// Null means the viewport frames the complete artboard.
  final ContentBoundsSpec? contentBoundsSpec;
}

/// Construction-time configuration for an editor surface.
///
/// Document adaptation and field read/write behavior are configured through
/// separate composition contracts.

@immutable
class EditorSurfaceFeatures {
  const EditorSurfaceFeatures({
    this.inspectorBuilder,
    this.inspectorSections = const <InspectorSectionBuilder>[],
    this.viewportFraming,
    this.interactionPolicy = const EditorInteractionPolicy(),
    this.viewportBehavior,
    this.selectionChromeMode,
    this.sceneObjectPolicy,
  });

  /// Optional exclusive complete-inspector override.
  ///
  /// Later extensions get the first opportunity to handle a selection.
  /// Returning null delegates to the earlier builder. If every override returns
  /// null, the standard inspector and its additive sections are rendered.
  final InspectorBuilder? inspectorBuilder;

  /// Additive body content for the standard inspector.
  ///
  /// Sections are evaluated in extension registration order and rendered before
  /// the standard inspector's intrinsic field content.
  ///
  /// Sections are ignored when an exclusive [inspectorBuilder] handles the
  /// current selection.
  final List<InspectorSectionBuilder> inspectorSections;

  /// Optional live-editor viewport framing.
  ///
  /// The default editor uses artboard framing. Extensions can provide
  /// content-bounds framing for focused editor experiences.
  ///
  /// This does not configure preview thumbnails or final export crop behavior.
  final EditorViewportFraming? viewportFraming;

  final EditorInteractionPolicy interactionPolicy;
  final CanvasViewportBehavior? viewportBehavior;

  /// Null uses the editor's standard transform controls.
  final SelectionChromeMode? selectionChromeMode;

  /// Optional policy for deriving object/layer rows from the editable scene.
  ///
  /// The default presentation uses generic node labels and direct node
  /// selection. Extensions can provide alternative labels and selection
  /// mapping.
  final SceneObjectPresentationPolicy? sceneObjectPolicy;

  EditorSurfaceFeatures merge(EditorSurfaceFeatures other) {
    return EditorSurfaceFeatures(
      inspectorBuilder: _composeInspectorBuilders(
        inspectorBuilder,
        other.inspectorBuilder,
      ),
      inspectorSections: <InspectorSectionBuilder>[
        ...inspectorSections,
        ...other.inspectorSections,
      ],
      viewportFraming: other.viewportFraming ?? viewportFraming,
      interactionPolicy: interactionPolicy.merge(other.interactionPolicy),
      viewportBehavior: other.viewportBehavior ?? viewportBehavior,
      selectionChromeMode: other.selectionChromeMode ?? selectionChromeMode,
      sceneObjectPolicy: other.sceneObjectPolicy ?? sceneObjectPolicy,
    );
  }
}
