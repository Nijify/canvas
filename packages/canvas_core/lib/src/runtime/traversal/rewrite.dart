// Path: lib/src/runtime/traversal/rewrite.dart

import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/runtime/model/node_mutations.dart';
import 'package:canvas_core/src/runtime/model/scene_document.dart';

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
/// If [id] does not exist, returns [doc] unchanged.
CanvasSceneDocument replaceById(
  CanvasSceneDocument doc,
  NodeId id,
  Node updated,
) {
  return rewriteSceneDocument(
    doc,
    (n) => rewritePostOrder(
      n,
      (m) => (m.id == id) ? updated : m,
      prune: (m) => m.id == id,
    ),
  );
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

    if (changed) n = n.withChildren(nextKids);
  }

  return fn(n);
}
