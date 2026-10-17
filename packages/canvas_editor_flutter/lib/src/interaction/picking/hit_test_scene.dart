// Path: packages/canvas_editor_flutter/lib/src/interaction/picking/hit_test_scene.dart

import 'dart:math' as math;

import 'package:canvas_core/canvas_core_runtime.dart'
    show
        CanvasSceneDocument,
        CanvasStroke,
        ComputedScene,
        DrawItem,
        ElementId,
        GroupNode,
        IconNode,
        ImageNode,
        Node,
        PathNode,
        Rect2D,
        TextNode,
        Vec2,
        strokeContributesToPaint;
import 'package:vector_math/vector_math_64.dart' as vm;

import 'package:canvas_editor_flutter/src/interaction/picking/path_hit_test.dart'
    show pathContainsClosedArea, pathHitsOutline;
import 'package:canvas_editor_flutter/src/interaction/geometry/editor_geometry_index.dart'
    show EditorGeometryIndex;

typedef NodeHitTest = bool Function(Node leaf);

/// Pick the topmost node at [worldPos] (canvas/world space).
///
/// Selection rule:
/// - default: select nearest group ancestor if selectable
/// - selectLeaf=true: select the leaf if selectable (else fallback to group)
///
/// Filtering:
/// - ignoreIds is subtree-aware via DrawItem.groupStack
///
/// Picking semantics:
/// - fill-area hit follows path geometry; open subpaths are treated as
///   implicitly closed for containment
/// - vector picking is selection-oriented and may be more permissive than
///   exact painted output
/// - icons use their nominal square, including holes and unused margins
/// - ordinary paths also use outline proximity
/// - thin strokes get a minimum screen-space hit slop

Node? pickTopAtScene(
  CanvasSceneDocument doc, // kept for API symmetry; not used internally
  Vec2 worldPos, {
  required ComputedScene computed,
  required EditorGeometryIndex geometry,
  bool selectLeaf = false,
  Set<ElementId> ignoreIds = const {},
  NodeHitTest? extraFilter,
  double viewportZoom = 1.0,
  double minPathHitSlopScreenPx = 6.0,
}) {
  final drawList = computed.drawList;

  // Topmost first: drawList is back-to-front paint order.
  for (var i = drawList.length - 1; i >= 0; i--) {
    final item = drawList[i];
    final leafId = item.leafId;

    // Subtree-aware ignore: if any ancestor group is ignored, skip this leaf.
    if (_anyGroupIgnored(item, ignoreIds)) continue;
    if (ignoreIds.contains(leafId)) continue;

    final leaf = computed.nodeById[leafId];
    if (leaf == null) continue;

    if (extraFilter != null && !extraFilter(leaf)) continue;

    if (!_hitLeafAt(
      leafId,
      leaf,
      worldPos,
      computed,
      geometry,
      viewportZoom: viewportZoom,
      minPathHitSlopScreenPx: minPathHitSlopScreenPx,
    )) {
      continue;
    }

    final picked = _choosePickedNode(
      leaf: leaf,
      groupStack: item.groupStack,
      computed: computed,
      ignoreIds: ignoreIds,
      preferLeaf: selectLeaf,
    );

    if (picked != null) return picked;
  }

  return null;
}

/// Convenience: pick the *leaf* only (ignores group-by-default semantics).

Node? pickLeafTopAtScene(
  CanvasSceneDocument doc,
  Vec2 worldPos, {
  required ComputedScene computed,
  required EditorGeometryIndex geometry,
  Set<ElementId> ignoreIds = const {},
  NodeHitTest? extraFilter,
  double viewportZoom = 1.0,
  double minPathHitSlopScreenPx = 6.0,
}) {
  return pickTopAtScene(
    doc,
    worldPos,
    computed: computed,
    geometry: geometry,
    selectLeaf: true,
    ignoreIds: ignoreIds,
    extraFilter: extraFilter,
    viewportZoom: viewportZoom,
    minPathHitSlopScreenPx: minPathHitSlopScreenPx,
  );
}

// ---------------------------------------------------------------------------
// Internal: selection decision
// ---------------------------------------------------------------------------

Node? _choosePickedNode({
  required Node leaf,
  required List<ElementId> groupStack,
  required ComputedScene computed,
  required Set<ElementId> ignoreIds,
  required bool preferLeaf,
}) {
  bool selectable(Node n) {
    return !ignoreIds.contains(n.id);
  }

  // Prefer leaf (modifier/double-click)
  if (preferLeaf && selectable(leaf)) return leaf;

  // Default: nearest selectable group ancestor (ids -> nodes)
  for (var j = groupStack.length - 1; j >= 0; j--) {
    final gid = groupStack[j];
    final g = computed.nodeById[gid];
    if (g == null) continue;
    if (g is! GroupNode) continue;
    if (selectable(g)) return g;
  }

  // Fallback: no selectable group, return selectable leaf.
  if (!preferLeaf && selectable(leaf)) return leaf;

  return null;
}

bool _anyGroupIgnored(DrawItem item, Set<ElementId> ignoreIds) {
  for (final gid in item.groupStack) {
    if (ignoreIds.contains(gid)) return true;
  }
  return false;
}

// ---------------------------------------------------------------------------
// Internal: geometry hit-test (leaf only)
// ---------------------------------------------------------------------------

bool _hitLeafAt(
  ElementId leafId,
  Node leaf,
  Vec2 worldPos,
  ComputedScene computed,
  EditorGeometryIndex geometry, {
  required double viewportZoom,
  required double minPathHitSlopScreenPx,
}) {
  final inv = geometry.inverseWorldById[leafId];
  if (inv == null) return false;

  // world -> local
  final p3 = vm.Vector3(worldPos.x, worldPos.y, 0);
  inv.transform3(p3);
  final local = Vec2(p3.x, p3.y);

  final localRect = computed.layoutBoundsLocalById[leafId];
  if (localRect == null) return false;

  final bool isVectorLeaf = leaf is PathNode;

  final localHitSlop = isVectorLeaf
      ? _localHitSlopForLeaf(
          inv,
          viewportZoom: viewportZoom,
          screenPx: minPathHitSlopScreenPx,
        )
      : 0.0;
  final outlineRadius = leaf is PathNode
      ? math.max(_strokeRadiusLocal(leaf.data.appearance.stroke), localHitSlop)
      : 0.0;

  // Layout is geometry only, so coarse rejection must include both stroke
  // width and the selection tolerance, including for zero-area line bounds.
  if (!_containsWithPadding(localRect, local, outlineRadius)) return false;

  return switch (leaf) {
    TextNode() => true,
    ImageNode() => true,

    IconNode() => true,

    PathNode(id: final id, data: final data) => () {
      final ir = computed.pathIRById[id];
      if (ir == null) return false;

      // Fill mode must not decide pickability. Closed geometry remains pickable
      // even when fill is CanvasFill.none().
      if (pathContainsClosedArea(ir, local, fillRule: data.fillRule)) {
        return true;
      }

      // Outline proximity remains interactive, with a minimum hit floor.
      return pathHitsOutline(ir, local, radiusLocal: outlineRadius);
    }(),

    _ => false,
  };
}

double _strokeRadiusLocal(CanvasStroke? stroke) {
  return strokeContributesToPaint(stroke) ? stroke!.width / 2.0 : 0.0;
}

double _localHitSlopForLeaf(
  vm.Matrix4 inverseWorld, {
  required double viewportZoom,
  required double screenPx,
}) {
  if (!viewportZoom.isFinite ||
      viewportZoom <= 0 ||
      !screenPx.isFinite ||
      screenPx <= 0) {
    return 0.0;
  }

  final m = inverseWorld.storage;
  final scale = math.max(
    math.max(m[0].abs(), m[4].abs()),
    math.max(m[1].abs(), m[5].abs()),
  );
  if (!scale.isFinite || scale == 0) return 0.0;
  final a = m[0] / scale, b = m[4] / scale;
  final c = m[1] / scale, d = m[5] / scale;
  // Largest singular value of the inverse linear transform. Unlike column
  // lengths, it preserves the screen-space floor under nested nonuniform
  // scales and rotations, which can compose into shear.
  final sum = math.sqrt((a + d) * (a + d) + (c - b) * (c - b));
  final difference = math.sqrt((a - d) * (a - d) + (c + b) * (c + b));
  return screenPx / viewportZoom * scale * (sum + difference) / 2;
}

bool _containsWithPadding(Rect2D r, Vec2 p, double pad) {
  return p.x >= r.left - pad &&
      p.x <= r.right + pad &&
      p.y >= r.top - pad &&
      p.y <= r.bottom + pad;
}
