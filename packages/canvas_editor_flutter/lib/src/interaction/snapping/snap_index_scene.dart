// Path: packages/canvas_editor_flutter/lib/src/interaction/snapping/snap_index_scene.dart

import 'package:canvas_core/canvas_core_runtime.dart'
    show
        CanvasSceneDocument,
        ComputedScene,
        DrawItem,
        ElementId,
        Rect2D,
        Rect2DX;
import 'package:canvas_editor_flutter/src/interaction/snapping/keylines.dart'
    show rectKeylines;
import 'package:canvas_editor_flutter/src/interaction/snapping/snap_types.dart'
    show SnapCandidate, SnapKind;
import 'package:canvas_editor_flutter/src/interaction/geometry/editor_geometry_index.dart'
    show EditorGeometryIndex;

/// Builds object-based snap candidates in world coordinates.
///
/// Hidden content is absent from the computed scene. Ignored subtrees are
/// excluded from candidates.
///
/// Eligible leaves contribute center and edge keylines. Eligible groups
/// contribute keylines derived from the union of their eligible descendants.

List<SnapCandidate> sceneObjectKeylines(
  CanvasSceneDocument doc,
  ComputedScene computed, {
  required EditorGeometryIndex geometry,
  Set<ElementId> ignoreIds = const {},
  bool includeLeaves = true,
  bool includeGroups = true,
}) {
  final out = <SnapCandidate>[];

  // Accumulate group bounds from eligible, non-ignored leaves.
  final groupBounds = <ElementId, Rect2D>{};

  bool anyGroupIgnored(DrawItem item) {
    for (final gid in item.groupStack) {
      if (ignoreIds.contains(gid)) return true;
    }
    return false;
  }

  // Walk leaves in paint order; use their already-computed world AABBs.
  for (final item in computed.drawList) {
    final leafId = item.leafId;

    // Subtree-aware ignore.
    if (anyGroupIgnored(item)) continue;
    if (ignoreIds.contains(leafId)) continue;

    final rect = geometry.layoutBoundsWorldById[leafId];
    if (rect == null) continue;

    if (includeLeaves) {
      out.addAll(rectKeylines(rect, SnapKind.object));
    }

    if (!includeGroups) continue;

    // Contribute this leaf rect to each ancestor group's bounds as long as
    // that group is not ignored.
    for (final gid in item.groupStack) {
      if (ignoreIds.contains(gid)) continue;

      final prev = groupBounds[gid];
      groupBounds[gid] = (prev == null) ? rect : Rect2DX.union(prev, rect);
    }
  }

  // Emit group candidates.
  if (includeGroups) {
    for (final rect in groupBounds.values) {
      out.addAll(rectKeylines(rect, SnapKind.object));
    }
  }

  return out;
}
