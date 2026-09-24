// Path: packages/canvas_core/lib/src/runtime/traversal/rewrite.dart

import 'package:canvas_core/src/foundation/ids.dart' show ElementId;
import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/runtime/model/scene_document.dart';
import 'package:canvas_core/src/runtime/traversal/traversal.dart'
    show collectAllNodeIds, findById;

/// Rewrite every root subtree in a scene document and preserve identity
/// when no root changed.
CanvasSceneDocument rewriteSceneDocument(
  CanvasSceneDocument doc,
  Node Function(Node) rewriteRoot,
) {
  var changedRoot = false;
  final nextRoot = <Node>[];

  for (final c in doc.children) {
    final nc = rewriteRoot(c);
    if (!identical(nc, c)) changedRoot = true;
    nextRoot.add(nc);
  }

  return changedRoot ? doc.copyWith(children: nextRoot) : doc;
}

/// Replace node [id] with [updated] anywhere in the tree.
///
/// If [id] does not exist, returns [doc] unchanged.
///
/// A replacement must preserve the target node ID. When the replacement
/// changes the target's descendants, its subtree IDs must also remain
/// nonblank, internally unique, and collision-free with nodes outside the
/// subtree being replaced.
CanvasSceneDocument replaceById(
  CanvasSceneDocument doc,
  ElementId id,
  Node updated,
) {
  final current = findById(doc, id);

  // Preserve the existing missing-target no-op contract.
  if (current == null) return doc;

  if (updated.id != id) {
    throw ArgumentError.value(
      updated.id,
      'updated.id',
      'Replacement node ID must match target ID "$id".',
    );
  }

  if (_replacementChangesDescendants(current, updated)) {
    // IDs belonging to the old subtree are intentionally excluded from the
    // collision set. The replacement is allowed to retain or rearrange those
    // IDs because the old subtree disappears atomically when replacement
    // succeeds.
    final replacedIds = collectAllNodeIds(root: current);

    final outsideIds = collectAllNodeIds(doc: doc)..removeAll(replacedIds);

    _validateReplacementSubtreeIds(updated, outsideIds);
  }

  return rewriteSceneDocument(
    doc,
    (n) => rewritePostOrder(
      n,
      (m) => (m.id == id) ? updated : m,
      prune: (m) => m.id == id,
    ),
  );
}

bool _replacementChangesDescendants(Node current, Node updated) {
  final currentChildren = current.childrenOrEmpty;
  final updatedChildren = updated.childrenOrEmpty;

  if (currentChildren.length != updatedChildren.length) {
    return true;
  }

  for (var i = 0; i < currentChildren.length; i++) {
    if (!identical(currentChildren[i], updatedChildren[i])) {
      return true;
    }
  }

  return false;
}

void _validateReplacementSubtreeIds(Node root, Set<ElementId> outsideIds) {
  final replacementIds = <ElementId>{};

  void walk(Node node) {
    final id = node.id;

    if (id.trim().isEmpty) {
      throw ArgumentError.value(
        id,
        'updated.id',
        'Replacement subtree node IDs must be nonblank.',
      );
    }

    if (!replacementIds.add(id)) {
      throw ArgumentError(
        'Replacement subtree contains duplicate node ID "$id".',
      );
    }

    if (outsideIds.contains(id)) {
      throw ArgumentError(
        'Replacement subtree node ID "$id" already exists outside '
        'the subtree being replaced.',
      );
    }

    for (final child in node.childrenOrEmpty) {
      walk(child);
    }
  }

  walk(root);
}

/// Post-order tree rewrite:
/// - Optionally rewrites children first (unless pruned)
/// - Then applies [fn] to the node
///
/// Controls:
/// - [skip]: if true, returns node as-is (no children rewrite, no fn)
/// - [prune]: if true, does NOT rewrite children but DOES run fn(node)
Node rewritePostOrder(
  Node n,
  Node Function(Node) fn, {
  bool Function(Node)? skip,
  bool Function(Node)? prune,
}) {
  if (skip != null && skip(n)) return n;

  final isPruned = prune != null && prune(n);

  if (!isPruned && n is GroupNode) {
    final kids = n.childrenOrEmpty;

    var changed = false;
    final nextKids = <Node>[];

    for (final c in kids) {
      final nc = rewritePostOrder(c, fn, skip: skip, prune: prune);
      if (!identical(nc, c)) changed = true;
      nextKids.add(nc);
    }

    if (changed) {
      n = n.copyWith(children: nextKids);
    }
  }

  return fn(n);
}
