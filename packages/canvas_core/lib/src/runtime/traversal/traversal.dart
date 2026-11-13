// Path: lib/src/runtime/traversal/traversal.dart

import 'package:canvas_core/src/foundation/ids.dart' show ElementId;
import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/runtime/model/scene_document.dart';

typedef ParentRef = ({Node? parent, int index});

/// Find a node anywhere in the tree.
Node? findById(CanvasSceneDocument doc, ElementId id) {
  Node? walk(Node n) {
    if (n.id == id) return n;
    if (!n.isGroup) return null;
    for (final c in n.childrenOrEmpty) {
      final hit = walk(c);
      if (hit != null) return hit;
    }
    return null;
  }

  for (final c in doc.children) {
    final hit = walk(c);
    if (hit != null) return hit;
  }
  return null;
}

/// Find parent + child-index of node [id].
/// If the node is a root child, returns (parent: null, index: i).
ParentRef? findParentOf(CanvasSceneDocument doc, ElementId id) {
  for (var i = 0; i < doc.children.length; i++) {
    if (doc.children[i].id == id) {
      return (parent: null, index: i);
    }
  }

  ParentRef? walk(Node parent) {
    final kids = parent.childrenOrEmpty;
    for (var i = 0; i < kids.length; i++) {
      final c = kids[i];
      if (c.id == id) return (parent: parent, index: i);
      if (c.isGroup) {
        final deeper = walk(c);
        if (deeper != null) return deeper;
      }
    }
    return null;
  }

  for (final c in doc.children) {
    if (!c.isGroup) continue;
    final r = walk(c);
    if (r != null) return r;
  }
  return null;
}

/// Collect all node IDs from a document or a subtree root.
Set<ElementId> collectAllNodeIds({CanvasSceneDocument? doc, Node? root}) {
  assert((doc == null) != (root == null));
  final roots = doc?.children ?? [root!];
  final out = <ElementId>{};

  void walk(Node n) {
    out.add(n.id);
    for (final c in n.childrenOrEmpty) {
      walk(c);
    }
  }

  for (final r in roots) {
    walk(r);
  }
  return out;
}

/// Visits every node in scene hierarchy order.
void visitSceneNodes(
  CanvasSceneDocument doc, {
  required void Function(Node node) visit,
}) {
  void walk(Node n) {
    visit(n);

    if (n.isGroup) {
      for (final c in n.childrenOrEmpty) {
        walk(c);
      }
    }
  }

  for (final r in doc.children) {
    walk(r);
  }
}
