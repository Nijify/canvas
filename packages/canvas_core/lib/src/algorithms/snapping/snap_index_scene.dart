// Path: lib/src/algorithms/snapping/snap_index_scene.dart

import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;
import 'package:canvas_core/src/foundation/geometry/geometry_ext.dart'
    show Rect2DX;

import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/runtime/model/scene_document.dart';

import 'package:canvas_core/src/algorithms/layout/computed_scene.dart'
    show ComputedScene, DrawItem;

import 'package:canvas_core/src/algorithms/snapping/keylines.dart'
    show rectKeylines;
import 'package:canvas_core/src/algorithms/snapping/snap_types.dart'
    show SnapCandidate, SnapKind;

/// Build object-based snap candidates (world coords) from the *computed* scene.
///
/// Semantics (matches old collectSceneBounds + filteredFlatLeaves):
/// - Hidden content is excluded (computeScene already skipped hidden).
/// - Locked nodes are excluded from candidates.
/// - `ignoreIds` is subtree-aware:
///   - if it contains a group id, all descendants are skipped
///   - if it contains a leaf id, that leaf is skipped
///
/// Candidates emitted:
/// - For each eligible leaf: center + edges.
/// - For each eligible group that has at least 1 eligible bounded descendant: center + edges.
List<SnapCandidate> sceneObjectKeylines(
  CanvasSceneDocument doc, // kept for API symmetry; not used internally
  ComputedScene computed, {
  Set<NodeId> ignoreIds = const {},
  bool includeLeaves = true,
  bool includeGroups = true,
}) {
  final out = <SnapCandidate>[];

  // Accumulate group bounds from eligible leaves only (unlocked + not ignored).
  final groupBounds = <NodeId, Rect2D>{};

  bool anyGroupIgnored(DrawItem item) {
    for (final gid in item.groupStack) {
      if (ignoreIds.contains(gid)) return true;
    }
    return false;
  }

  bool groupIsLocked(NodeId gid) {
    final g = computed.nodeById[gid];
    if (g == null) return false;
    return g.locked;
  }

  // Walk leaves in paint order; use their already-computed world AABBs.
  for (final item in computed.drawList) {
    final leafId = item.leafId;

    // Subtree-aware ignore
    if (anyGroupIgnored(item)) continue;
    if (ignoreIds.contains(leafId)) continue;

    final leaf = computed.nodeById[leafId];
    if (leaf == null) continue;

    // Snap candidates exclude locked nodes (matches old includeLocked:false)
    if (leaf.locked) continue;

    final rect = computed.visualBoundsWorldById[leafId];
    if (rect == null) continue;

    if (includeLeaves) {
      out.addAll(rectKeylines(rect, SnapKind.object));
    }

    if (!includeGroups) continue;

    // Contribute this leaf rect to each ancestor group’s bounds,
    // as long as the group itself isn’t ignored/locked.
    for (final gid in item.groupStack) {
      if (ignoreIds.contains(gid)) continue;
      if (groupIsLocked(gid)) continue;

      final prev = groupBounds[gid];
      groupBounds[gid] = (prev == null) ? rect : Rect2DX.union(prev, rect);
    }
  }

  // Emit group candidates
  if (includeGroups) {
    for (final rect in groupBounds.values) {
      out.addAll(rectKeylines(rect, SnapKind.object));
    }
  }

  return out;
}
