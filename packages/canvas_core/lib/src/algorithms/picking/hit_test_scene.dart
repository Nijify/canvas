// Path: lib/src/algorithms/picking/hit_test_scene.dart

import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart' as vm;

import 'package:canvas_core/src/foundation/core_types.dart' show Vec2;
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;

import 'package:canvas_core/src/path/path_hit_test.dart'
    show pathContainsClosedArea, pathHitsOutline;

import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/runtime/model/scene_document.dart';

import 'package:canvas_core/src/algorithms/layout/computed_scene.dart'
    show ComputedScene, DrawItem;
import 'package:canvas_core/src/path/path_ir.dart' show PathIR;

typedef NodeHitTest = bool Function(Node leaf);

/// Pick the topmost node at [worldPos] (canvas/world space).
///
/// Selection rule:
/// - default: select nearest group ancestor (LogoNode/GroupNode) if selectable
/// - selectLeaf=true: select the leaf if selectable (else fallback to group)
///
/// Filtering:
/// - locked filtering applies to what you RETURN (unless includeLocked=true)
/// - ignoreIds is subtree-aware via DrawItem.groupStack
///
/// Picking semantics:
/// - fill-area hit follows path geometry; open subpaths are treated as
///   implicitly closed for containment
/// - vector picking is selection-oriented and may be more permissive than
///   exact painted output
/// - paths/icons also use outline proximity
/// - thin strokes get a minimum screen-space hit slop
Node? pickTopAtScene(
  CanvasSceneDocument doc, // kept for API symmetry; not used internally
  Vec2 worldPos, {
  required ComputedScene computed,
  bool includeLocked = false,
  bool selectLeaf = false,
  Set<NodeId> ignoreIds = const {},
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

    if (!includeLocked && leaf.locked) continue;
    if (extraFilter != null && !extraFilter(leaf)) continue;

    if (!_hitLeafAt(
      leafId,
      leaf,
      worldPos,
      computed,
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
      includeLocked: includeLocked,
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
  bool includeLocked = false,
  Set<NodeId> ignoreIds = const {},
  NodeHitTest? extraFilter,
  double viewportZoom = 1.0,
  double minPathHitSlopScreenPx = 6.0,
}) {
  return pickTopAtScene(
    doc,
    worldPos,
    computed: computed,
    includeLocked: includeLocked,
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
  required List<NodeId> groupStack,
  required ComputedScene computed,
  required Set<NodeId> ignoreIds,
  required bool includeLocked,
  required bool preferLeaf,
}) {
  bool selectable(Node n) {
    if (ignoreIds.contains(n.id)) return false;
    if (!includeLocked && n.locked) return false;
    return true;
  }

  // Prefer leaf (modifier/double-click)
  if (preferLeaf && selectable(leaf)) return leaf;

  // Default: nearest selectable group ancestor (ids -> nodes)
  for (var j = groupStack.length - 1; j >= 0; j--) {
    final gid = groupStack[j];
    final g = computed.nodeById[gid];
    if (g == null) continue;
    if (!g.isGroup) continue;
    if (selectable(g)) return g;
  }

  // Fallback: no selectable group, return selectable leaf.
  if (!preferLeaf && selectable(leaf)) return leaf;

  return null;
}

bool _anyGroupIgnored(DrawItem item, Set<NodeId> ignoreIds) {
  for (final gid in item.groupStack) {
    if (ignoreIds.contains(gid)) return true;
  }
  return false;
}

// ---------------------------------------------------------------------------
// Internal: geometry hit-test (leaf only)
// ---------------------------------------------------------------------------

bool _hitLeafAt(
  NodeId leafId,
  Node leaf,
  Vec2 worldPos,
  ComputedScene computed, {
  required double viewportZoom,
  required double minPathHitSlopScreenPx,
}) {
  final inv = computed.inverseWorldById[leafId];
  if (inv == null) return false;

  // world -> local
  final p3 = vm.Vector3(worldPos.x, worldPos.y, 0);
  inv.transform3(p3);
  final local = Vec2(p3.x, p3.y);

  final localRect = computed.localBoundsById[leafId];
  if (localRect == null) return false;

  final bool isVectorLeaf =
      leaf is PathNode ||
      (leaf is IconNode && computed.iconPathIRById[leafId] != null);

  final localHitSlop = isVectorLeaf
      ? _localHitSlopForLeaf(
          leafId,
          computed,
          viewportZoom: viewportZoom,
          screenPx: minPathHitSlopScreenPx,
        )
      : 0.0;

  // Cheap reject only; for vector content it must be slop-aware.
  if (!_containsWithPadding(localRect, local, localHitSlop)) return false;

  return switch (leaf) {
    TextNode() => true,
    ImageNode() => true,

    IconNode(id: final id) => () {
      final ir = computed.iconPathIRById[id];
      if (ir == null) return true;

      if (pathContainsClosedArea(ir, local)) return true;

      final outlineRadius = math.max(
        _visibleStrokeRadiusLocal(ir),
        localHitSlop,
      );
      return pathHitsOutline(ir, local, radiusLocal: outlineRadius);
    }(),

    PathNode(id: final id) => () {
      final ir = computed.pathIRById[id];
      if (ir == null) return false;

      // Fill mode must not decide pickability. Closed geometry remains pickable
      // even when fill is CanvasFill.none().
      if (pathContainsClosedArea(ir, local)) return true;

      // Outline proximity remains interactive, with a minimum hit floor.
      final outlineRadius = math.max(
        _visibleStrokeRadiusLocal(ir),
        localHitSlop,
      );
      return pathHitsOutline(ir, local, radiusLocal: outlineRadius);
    }(),

    _ => false,
  };
}

double _visibleStrokeRadiusLocal(PathIR ir) {
  final hasVisibleStroke = ir.style.stroke != null && ir.style.strokeWidth > 0;
  return hasVisibleStroke ? ir.style.strokeWidth / 2.0 : 0.0;
}

double _localHitSlopForLeaf(
  NodeId leafId,
  ComputedScene computed, {
  required double viewportZoom,
  required double screenPx,
}) {
  if (viewportZoom <= 0 || screenPx <= 0) return 0.0;

  final world = computed.worldById[leafId];
  if (world == null) return 0.0;

  final o = vm.Vector3.zero();
  final x = vm.Vector3(1, 0, 0);
  final y = vm.Vector3(0, 1, 0);

  world.transform3(o);
  world.transform3(x);
  world.transform3(y);

  final sxWorld = math.sqrt(
    (x.x - o.x) * (x.x - o.x) + (x.y - o.y) * (x.y - o.y),
  );
  final syWorld = math.sqrt(
    (y.x - o.x) * (y.x - o.x) + (y.y - o.y) * (y.y - o.y),
  );

  // Conservative under non-uniform scale: use the smaller axis so hit slop
  // never becomes too small in local space.
  final screenPxPerLocalUnit = math.max(
    1e-6,
    math.min(sxWorld, syWorld) * viewportZoom,
  );

  return screenPx / screenPxPerLocalUnit;
}

bool _containsWithPadding(Rect2D r, Vec2 p, double pad) {
  return p.x >= r.left - pad &&
      p.x <= r.right + pad &&
      p.y >= r.top - pad &&
      p.y <= r.bottom + pad;
}
