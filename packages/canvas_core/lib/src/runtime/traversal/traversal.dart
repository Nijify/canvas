// Path: oss_packages/canvas_core/lib/src/runtime/traversal/traversal.dart

import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/runtime/model/scene_document.dart';

typedef ParentRef = ({Node? parent, int index});

/// Find a node anywhere in the tree.
Node? findById(CanvasSceneDocument doc, NodeId id) {
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
ParentRef? findParentOf(CanvasSceneDocument doc, NodeId id) {
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
Set<NodeId> collectAllNodeIds({CanvasSceneDocument? doc, Node? root}) {
  assert((doc == null) != (root == null));
  final roots = doc?.children ?? [root!];
  final out = <NodeId>{};

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

/// Pure traversal: iterate all nodes (optionally skipping hidden subtrees).
void visitSceneNodes(
  CanvasSceneDocument doc, {
  bool includeHidden = false,
  required void Function(Node node) visit,
}) {
  void walk(Node n, bool ancestorHidden) {
    final hidden = ancestorHidden || n.hidden;
    if (!includeHidden && hidden) return;

    visit(n);

    if (n.isGroup) {
      for (final c in n.childrenOrEmpty) {
        walk(c, hidden);
      }
    }
  }

  for (final r in doc.children) {
    walk(r, false);
  }
}
