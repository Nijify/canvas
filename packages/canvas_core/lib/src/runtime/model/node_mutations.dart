// Path: lib/src/runtime/model/node_mutations.dart
/// TODO(api): This is temporarily exported until a stable NodeEditingX API is
/// available. Before public stabilization, split into:
/// - public NodeEditingX: safe immutable edits like withXf/withHidden/withName
/// - internal structural helpers: withId/withChildren
library;

import 'package:canvas_core/src/runtime/model/node_model.dart';

String? normalizeLayerName(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;
  return value.length <= 80 ? value : value.substring(0, 80);
}

/// Internal helpers to centralize "switch-on-node-type + copyWith(...)"
/// for common mutations.
extension NodeMutations on Node {
  Node withName(String? name) {
    final normalized = normalizeLayerName(name);

    return switch (this) {
      final TextNode n => n.copyWith(name: normalized),
      final ImageNode n => n.copyWith(name: normalized),
      final PathNode n => n.copyWith(name: normalized),
      final IconNode n => n.copyWith(name: normalized),
      final GroupNode n => n.copyWith(name: normalized),
    };
  }

  Node withXf(Transform2D xf) => switch (this) {
    final TextNode n => n.copyWith(xf: xf),
    final ImageNode n => n.copyWith(xf: xf),
    final PathNode n => n.copyWith(xf: xf),
    final IconNode n => n.copyWith(xf: xf),
    final GroupNode n => n.copyWith(xf: xf),
  };

  Node withHidden(bool hidden) => switch (this) {
    final TextNode n => n.copyWith(hidden: hidden),
    final ImageNode n => n.copyWith(hidden: hidden),
    final PathNode n => n.copyWith(hidden: hidden),
    final IconNode n => n.copyWith(hidden: hidden),
    final GroupNode n => n.copyWith(hidden: hidden),
  };

  Node withLocked(bool locked) => switch (this) {
    final TextNode n => n.copyWith(locked: locked),
    final ImageNode n => n.copyWith(locked: locked),
    final PathNode n => n.copyWith(locked: locked),
    final IconNode n => n.copyWith(locked: locked),
    final GroupNode n => n.copyWith(locked: locked),
  };

  Node withId(NodeId id) => switch (this) {
    final TextNode n => n.copyWith(id: id),
    final ImageNode n => n.copyWith(id: id),
    final PathNode n => n.copyWith(id: id),
    final IconNode n => n.copyWith(id: id),
    final GroupNode n => n.copyWith(id: id),
  };

  /// Only groups accept children; non-groups return themselves unchanged.
  Node withChildren(List<Node> kids) => switch (this) {
    final GroupNode n => n.copyWith(children: kids),
    _ => this,
  };
}
