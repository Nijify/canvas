// Path: lib/src/runtime/traversal/scene_tree_ops.dart

import 'package:canvas_core/src/foundation/core_types.dart' show Vec2;
import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/runtime/model/node_mutations.dart';
import 'package:canvas_core/src/runtime/model/scene_document.dart'
    show CanvasSceneDocument;
import 'package:canvas_core/src/runtime/traversal/traversal.dart'
    show ParentRef, collectAllNodeIds, findById, findParentOf;
import 'package:canvas_core/src/runtime/traversal/rewrite.dart'
    show replaceById;

typedef IdGenerator = String Function(String oldId);

typedef DuplicateSceneSubtreeResult = ({
  CanvasSceneDocument doc,
  Map<NodeId, NodeId> idMap,
  List<NodeId> createdIds,
  NodeId? primaryId,
});

typedef DeleteSceneSubtreeResult = ({
  CanvasSceneDocument doc,
  Set<NodeId> deletedIds,
});

abstract final class SceneTreeOps {
  // -------------------------------------------------------------------------
  // CRUD
  // -------------------------------------------------------------------------

  static CanvasSceneDocument addNode(
    CanvasSceneDocument doc,
    Node node, {
    NodeId? parentId,
    int? index,
  }) {
    if (parentId == null) {
      final out = [...doc.children];
      final i = _clampInsertIndex(index ?? out.length, out.length);
      out.insert(i, node);
      return doc.copyWith(children: out);
    }

    final parent = findById(doc, parentId);
    if (parent == null || !parent.isGroup) return doc;

    final outKids = [...parent.childrenOrEmpty];
    final i = _clampInsertIndex(index ?? outKids.length, outKids.length);
    outKids.insert(i, node);

    return _replaceChildren(doc, parent, outKids);
  }

  /// Removes the subtree rooted at [id] (node + descendants).
  /// Returns [doc] unchanged if id not found.
  static CanvasSceneDocument removeSubtree(CanvasSceneDocument doc, NodeId id) {
    final pr = findParentOf(doc, id);
    if (pr == null) return doc;
    return _removeAtParentRef(doc, pr);
  }

  /// Delete + return the full id set that was removed.
  static DeleteSceneSubtreeResult deleteSubtree(
    CanvasSceneDocument doc,
    NodeId id,
  ) {
    final node = findById(doc, id);
    if (node == null) return (doc: doc, deletedIds: const <NodeId>{});

    final deletedIds = collectAllNodeIds(root: node);
    final nextDoc = removeSubtree(doc, id);
    return (doc: nextDoc, deletedIds: deletedIds);
  }

  static CanvasSceneDocument moveSubtree(
    CanvasSceneDocument doc,
    NodeId id, {
    NodeId? newParentId,
    int? toIndex,
  }) {
    final node = findById(doc, id);
    if (node == null) return doc;

    // Prevent cycles and invalid parents.
    if (newParentId != null) {
      if (newParentId == id) return doc;

      final np = findById(doc, newParentId);
      if (np == null || !np.isGroup) return doc;

      if (_containsId(node, newParentId)) return doc;
    }

    final pr = findParentOf(doc, id);
    if (pr == null) return doc;

    final oldParentId = pr.parent?.id;
    final sameParent = oldParentId == newParentId;

    if (sameParent) {
      final siblings = (pr.parent == null)
          ? [...doc.children]
          : [...pr.parent!.childrenOrEmpty];

      final moving = siblings.removeAt(pr.index);
      final i = _clampInsertIndex(toIndex ?? siblings.length, siblings.length);
      siblings.insert(i, moving);

      return _replaceChildren(doc, pr.parent, siblings);
    }

    final d1 = _removeAtParentRef(doc, pr);
    return addNode(d1, node, parentId: newParentId, index: toIndex);
  }

  // -------------------------------------------------------------------------
  // Duplicate
  // -------------------------------------------------------------------------

  static DuplicateSceneSubtreeResult duplicateSubtree(
    CanvasSceneDocument doc,
    NodeId id, {
    Vec2 shift = const Vec2(16, 16),
    IdGenerator? idGen,
  }) {
    final node = findById(doc, id);
    if (node == null) {
      return (doc: doc, idMap: const {}, createdIds: const [], primaryId: null);
    }

    final pr = findParentOf(doc, id);
    if (pr == null) {
      return (doc: doc, idMap: const {}, createdIds: const [], primaryId: null);
    }

    final gen = idGen ?? _defaultIdGen();

    final created = <NodeId>[];
    final idMap = <NodeId, NodeId>{};

    Node clone(Node n) {
      final newId = gen(n.id);
      idMap[n.id] = newId;
      created.add(newId);

      final kids = n.childrenOrEmpty;
      final clonedKids = kids.isEmpty
          ? const <Node>[]
          : [for (final c in kids) clone(c)];

      return n.withId(newId).withChildren(clonedKids);
    }

    // Clone subtree.
    var cloned = clone(node);

    // Shift root position only.
    final xf0 = cloned.xf;
    cloned = cloned.withXf(xf0.copyWith(position: xf0.position + shift));

    // Insert immediately after original.
    // Later siblings paint above earlier siblings, so the duplicate appears above.
    final insertIndex = pr.index + 1;

    CanvasSceneDocument out;
    if (pr.parent == null) {
      final kids = [...doc.children];
      kids.insert(_clampInsertIndex(insertIndex, kids.length), cloned);
      out = doc.copyWith(children: kids);
    } else {
      final kids = [...pr.parent!.childrenOrEmpty];
      kids.insert(_clampInsertIndex(insertIndex, kids.length), cloned);
      out = _replaceChildren(doc, pr.parent, kids);
    }

    return (doc: out, idMap: idMap, createdIds: created, primaryId: cloned.id);
  }

  // -------------------------------------------------------------------------
  // Transform ops
  // -------------------------------------------------------------------------

  static CanvasSceneDocument replaceNodeXf(
    CanvasSceneDocument doc,
    NodeId id,
    Transform2D xf,
  ) {
    final node = findById(doc, id);
    if (node == null || node.locked) return doc;
    return replaceById(doc, id, node.withXf(xf));
  }

  static CanvasSceneDocument translate(
    CanvasSceneDocument doc,
    NodeId id,
    Vec2 delta,
  ) {
    final node = findById(doc, id);
    if (node == null || node.locked) return doc;
    final xf = node.xf;
    return replaceNodeXf(doc, id, xf.copyWith(position: xf.position + delta));
  }

  static CanvasSceneDocument rotate(
    CanvasSceneDocument doc,
    NodeId id,
    double deltaRad,
  ) {
    final node = findById(doc, id);
    if (node == null || node.locked) return doc;
    final xf = node.xf;
    return replaceNodeXf(
      doc,
      id,
      xf.copyWith(rotationRad: xf.rotationRad + deltaRad),
    );
  }

  static CanvasSceneDocument uniformScale(
    CanvasSceneDocument doc,
    NodeId id,
    double mul,
  ) {
    final node = findById(doc, id);
    if (node == null || node.locked) return doc;
    final xf = node.xf;
    final s = xf.scale;
    return replaceNodeXf(
      doc,
      id,
      xf.copyWith(scale: Vec2(s.x * mul, s.y * mul)),
    );
  }

  // -------------------------------------------------------------------------
  // Stack order
  // -------------------------------------------------------------------------

  /// Moves [id] to the front of its sibling stack.
  ///
  /// Sibling order is paint order:
  /// - earlier siblings paint behind
  /// - later siblings paint in front
  static CanvasSceneDocument bringToFront(CanvasSceneDocument doc, NodeId id) {
    return _moveWithinCurrentParent(
      doc,
      id,
      targetIndexFor: (_, count) => count - 1,
    );
  }

  /// Moves [id] to the back of its sibling stack.
  static CanvasSceneDocument sendToBack(CanvasSceneDocument doc, NodeId id) {
    return _moveWithinCurrentParent(doc, id, targetIndexFor: (_, _) => 0);
  }

  /// Moves [id] one step toward the front within its sibling stack.
  static CanvasSceneDocument bringForward(CanvasSceneDocument doc, NodeId id) {
    return _moveWithinCurrentParent(
      doc,
      id,
      targetIndexFor: (index, _) => index + 1,
    );
  }

  /// Moves [id] one step toward the back within its sibling stack.
  static CanvasSceneDocument sendBackward(CanvasSceneDocument doc, NodeId id) {
    return _moveWithinCurrentParent(
      doc,
      id,
      targetIndexFor: (index, _) => index - 1,
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  static CanvasSceneDocument _moveWithinCurrentParent(
    CanvasSceneDocument doc,
    NodeId id, {
    required int Function(int currentIndex, int siblingCount) targetIndexFor,
  }) {
    final pr = findParentOf(doc, id);
    if (pr == null) return doc;

    final siblings = (pr.parent == null)
        ? [...doc.children]
        : [...pr.parent!.childrenOrEmpty];

    if (siblings.length < 2) return doc;

    final target = _clampExistingIndex(
      targetIndexFor(pr.index, siblings.length),
      siblings.length,
    );

    if (target == pr.index) return doc;

    final moving = siblings.removeAt(pr.index);
    siblings.insert(target, moving);

    return _replaceChildren(doc, pr.parent, siblings);
  }

  static CanvasSceneDocument _removeAtParentRef(
    CanvasSceneDocument doc,
    ParentRef pr,
  ) {
    if (pr.parent == null) {
      final out = [...doc.children]..removeAt(pr.index);
      return doc.copyWith(children: out);
    }

    final p = pr.parent!;
    final kids = [...p.childrenOrEmpty]..removeAt(pr.index);
    return _replaceChildren(doc, p, kids);
  }

  static CanvasSceneDocument _replaceChildren(
    CanvasSceneDocument doc,
    Node? parent,
    List<Node> children,
  ) {
    if (parent == null) {
      return doc.copyWith(children: children);
    }

    return replaceById(doc, parent.id, parent.withChildren(children));
  }

  static bool _containsId(Node root, NodeId needle) {
    bool walk(Node n) {
      if (n.id == needle) return true;
      for (final c in n.childrenOrEmpty) {
        if (walk(c)) return true;
      }
      return false;
    }

    return walk(root);
  }

  static int _clampInsertIndex(int value, int length) {
    return value.clamp(0, length).toInt();
  }

  static int _clampExistingIndex(int value, int length) {
    assert(length > 0);
    return value.clamp(0, length - 1).toInt();
  }

  static IdGenerator _defaultIdGen() {
    var counter = 0;
    return (oldId) {
      counter++;
      return '${oldId}_copy_$counter';
    };
  }
}
