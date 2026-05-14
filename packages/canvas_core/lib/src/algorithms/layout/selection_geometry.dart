// Path: lib/src/algorithms/layout/selection_geometry.dart
//
// Helpers for aggregating multi-selection geometry in world space.

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;
import 'package:canvas_core/src/foundation/geometry/geometry_ext.dart';
import 'package:canvas_core/src/foundation/ids.dart';

/// Axis-aligned union of the provided ids' bounds.
///
/// [getBounds] should return world-space AABBs for individual elements.
/// In runtime/editor, [getBounds] is typically backed by
/// `ComputedScene.visualBoundsWorldById` (computed once in the compute stage).
///
/// Returns `null` when there are no ids or no available bounds.

Rect2D? selectionUnionBounds(
  Iterable<ElementId> ids, {
  required Rect2D? Function(ElementId id) getBounds,
}) {
  Rect2D? acc;
  for (final id in ids) {
    final b = getBounds(id);
    if (b == null) continue;
    acc = (acc == null) ? b : Rect2DX.union(acc, b);
  }
  return acc;
}

/// Aggregated world-space geometry for a multi-element selection.
///
/// Provides unified bounding box, corner positions, handle positions,
/// and a pivot point for transformations (rotation, scaling) applied
/// to multiple selected elements as a group.
///
/// - [bounds]: Axis-aligned bounding box encompassing all selected elements.
/// - [corners]: Four corners (TL, TR, BR, BL) of the bounding box.
/// - [handles]: Corner and edge midpoint positions for interactive handles.
/// - [pivotWorld]: Center of the bounding box, used as the pivot for transforms.
class MultiSelectGeometry {
  final Rect2D bounds;
  final List<Vec2> corners; // TL, TR, BR, BL
  final List<Vec2> handles; // ordered: corners then edge midpoints
  final Vec2 pivotWorld;

  const MultiSelectGeometry({
    required this.bounds,
    required this.corners,
    required this.handles,
    required this.pivotWorld,
  });
}

/// Convenience wrapper that builds [MultiSelectGeometry] from element bounds.
MultiSelectGeometry? selectionGeometry(
  Iterable<ElementId> ids, {
  required Rect2D? Function(ElementId id) getBounds,
}) {
  final bounds = selectionUnionBounds(ids, getBounds: getBounds);
  if (bounds == null) return null;

  final corners = <Vec2>[
    Vec2(bounds.left, bounds.top),
    Vec2(bounds.right, bounds.top),
    Vec2(bounds.right, bounds.bottom),
    Vec2(bounds.left, bounds.bottom),
  ];

  final handles = <Vec2>[
    ...corners,
    Vec2((bounds.left + bounds.right) * 0.5, bounds.top),
    Vec2(bounds.right, (bounds.top + bounds.bottom) * 0.5),
    Vec2((bounds.left + bounds.right) * 0.5, bounds.bottom),
    Vec2(bounds.left, (bounds.top + bounds.bottom) * 0.5),
  ];

  return MultiSelectGeometry(
    bounds: bounds,
    corners: corners,
    handles: handles,
    pivotWorld: bounds.center,
  );
}
