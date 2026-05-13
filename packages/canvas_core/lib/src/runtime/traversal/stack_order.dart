// Path: oss_packages/canvas_core/lib/src/runtime/traversal/stack_order.dart

import 'package:canvas_core/src/runtime/model/node_model.dart';

/// Sibling order is paint order:
/// - first child paints behind
/// - last child paints in front
List<Node> nodesInPaintOrder(List<Node> children) => children;

/// Layer panels typically show frontmost first.
List<Node> nodesInFrontToBackOrder(List<Node> children) {
  return children.reversed.toList(growable: false);
}
