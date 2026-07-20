// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/layers/scene_object_tree.dart
// ignore_for_file: unreachable_switch_case

import 'package:canvas_core/canvas_core_runtime.dart' as rt;

/// Generic editor-facing object kind used by layers/object-tree UI.
///
/// This is presentation/editor semantics, not core runtime schema.
enum SceneObjectKind { text, image, path, icon, group, unknown }

/// One row in the editor's headless object/layer tree.
///
/// The row is deliberately UI-neutral:
/// - [id] is the node represented by the row.
/// - [selectionId] is the node id a layer panel should select on row click.
/// - [depth] is visual tree indentation depth.
class SceneObjectRow {
  const SceneObjectRow({
    required this.id,
    required this.selectionId,
    required this.depth,
    required this.label,
    required this.kind,
    required this.hidden,
    required this.locked,
  });

  final String id;
  final String selectionId;
  final int depth;
  final String label;
  final SceneObjectKind kind;
  final bool hidden;
  final bool locked;
}

/// Presentation policy for deriving layer/object rows from the canonical scene.
///
/// Base canvas_editor_flutter stays generic. Extension packages can override
/// this to provide domain-specific labels and selection mapping.
class SceneObjectPresentationPolicy {
  const SceneObjectPresentationPolicy();

  String labelForNode(rt.CanvasSceneDocument scene, rt.Node node) {
    final explicit = node.name?.trim();

    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    return fallbackLabelForNode(node);
  }

  String selectionIdForNode(rt.CanvasSceneDocument scene, rt.Node node) {
    return node.id;
  }
}

/// Pure, headless layer/object-tree builder.
///
/// Important:
/// - Input scene must be the editable/base scene, not the render/prepared scene.
/// - Output order is front-to-back because layer panels usually show topmost
///   objects first.
/// - The builder does not know about widgets, controllers, or
///   application-provided behavior.
class SceneObjectTreeBuilder {
  const SceneObjectTreeBuilder({
    this.policy = const SceneObjectPresentationPolicy(),
  });

  final SceneObjectPresentationPolicy policy;

  List<SceneObjectRow> build({required rt.CanvasSceneDocument scene}) {
    final rows = <SceneObjectRow>[];

    void visit(rt.Node node, int depth) {
      rows.add(
        SceneObjectRow(
          id: node.id,
          selectionId: policy.selectionIdForNode(scene, node),
          depth: depth,
          label: policy.labelForNode(scene, node),
          kind: kindForNode(node),
          hidden: node.hidden,
          locked: node.locked,
        ),
      );

      if (node is rt.GroupNode) {
        for (final child in rt.nodesInFrontToBackOrder(node.children)) {
          visit(child, depth + 1);
        }
      }
    }

    for (final root in rt.nodesInFrontToBackOrder(scene.children)) {
      visit(root, 0);
    }

    return List<SceneObjectRow>.unmodifiable(rows);
  }
}

SceneObjectKind kindForNode(rt.Node node) {
  return switch (node) {
    rt.TextNode() => SceneObjectKind.text,
    rt.ImageNode() => SceneObjectKind.image,
    rt.PathNode() => SceneObjectKind.path,
    rt.IconNode() => SceneObjectKind.icon,
    rt.GroupNode() => SceneObjectKind.group,
    _ => SceneObjectKind.unknown,
  };
}

String fallbackLabelForNode(rt.Node node) {
  return switch (node) {
    rt.TextNode(:final data) => _fallbackTextLabel(data.text),
    rt.ImageNode() => 'Image',
    rt.PathNode(:final data) => _fallbackPathLabel(data.source),
    rt.IconNode() => 'Icon',
    rt.GroupNode() => 'Group',
    _ => 'Layer',
  };
}

String _fallbackTextLabel(String text) {
  final cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.isEmpty) return 'Text';
  if (cleaned.length <= 32) return cleaned;
  return '${cleaned.substring(0, 32)}…';
}

String _fallbackPathLabel(rt.PathSource? source) {
  return switch (source) {
    rt.RectSource() => 'Rectangle',
    rt.RoundRectSource() => 'Rounded Rectangle',
    rt.PillSource() => 'Pill',
    rt.CircleSource() => 'Circle',
    rt.EllipseSource() => 'Ellipse',
    rt.UnderlineSource() => 'Underline',
    rt.RegularPolygonSource() => 'Polygon',
    rt.StarSource() => 'Star',
    rt.SvgPathSource() => 'Path',
    null => 'Shape',
    _ => 'Shape',
  };
}
