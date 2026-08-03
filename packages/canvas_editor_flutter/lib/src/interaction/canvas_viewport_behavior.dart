// Path: oss_packages/canvas_editor_flutter/lib/src/interaction/canvas_viewport_behavior.dart

import 'package:flutter/widgets.dart';
import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:canvas_editor_flutter/src/editor_api.dart';
import 'package:canvas_editor_flutter/src/editor_hosts.dart'
    show EditorSelectionHost;

@immutable
class CanvasViewportBehaviorContext {
  const CanvasViewportBehaviorContext({
    required this.render,
    required this.selection,
    required this.controller,
  });

  final rt.RenderSnapshot render;
  final EditorSelectionHost selection;
  final EditorController controller;
}

@immutable
class CanvasHitTestResult {
  const CanvasHitTestResult({required this.leaf, required this.node});

  /// Topmost editable leaf hit.
  final rt.Node? leaf;

  /// Topmost selectable/group-level hit.
  final rt.Node? node;
}

@immutable
final class CanvasDragStartIntent {
  const CanvasDragStartIntent.move(String this.dragId);

  const CanvasDragStartIntent.noMove() : dragId = null;

  final String? dragId;
}

/// Optional viewport behavior extension.
///
/// The viewport provides:
/// - hit testing
/// - normal selection
/// - drag session lifecycle
/// - snapping
/// - pan/zoom
///
/// Optional behaviors may fully handle a selection interaction or provide
/// foreground UI.
abstract class CanvasViewportBehavior {
  const CanvasViewportBehavior();

  Listenable? listenable(BuildContext context) => null;

  bool handleTapSelection(
    BuildContext context,
    CanvasViewportBehaviorContext ctx,
    CanvasHitTestResult hit,
  ) {
    return false;
  }

  CanvasDragStartIntent? resolveDragStartSelection(
    BuildContext context,
    CanvasViewportBehaviorContext ctx,
    CanvasHitTestResult hit,
    ScaleStartDetails details,
  ) {
    return null;
  }

  Widget? buildForeground(
    BuildContext context,
    CanvasViewportBehaviorContext ctx,
  ) {
    return null;
  }
}
