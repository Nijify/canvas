// Path: packages/canvas_editor_flutter/lib/src/interaction/geometry/selection_geometry.dart

import 'package:canvas_core/canvas_core_runtime.dart'
    show ElementId, Rect2D, Rect2DX, Vec2;

/// Axis-aligned union of the provided ids' interaction bounds.
///
/// [getBounds] should return world-space editor interaction AABBs.
///
/// Returns `null` when there are no ids or no available bounds.
Rect2D? selectionUnionBounds(
  Iterable<ElementId> ids, {
  required Rect2D? Function(ElementId id) getBounds,
}) {
  Rect2D? acc;

  for (final id in ids) {
    final bounds = getBounds(id);
    if (bounds == null) continue;

    acc = acc == null ? bounds : Rect2DX.union(acc, bounds);
  }

  return acc;
}

/// Aggregated world-space geometry for a multi-element selection.
///
/// [bounds] is the axis-aligned union of all selected interaction bounds.
/// [corners] are TL, TR, BR, BL.
/// [handles] contains corners followed by edge midpoints.
/// [pivotWorld] is the center of the aggregate bounds.
final class MultiSelectGeometry {
  const MultiSelectGeometry({
    required this.bounds,
    required this.corners,
    required this.handles,
    required this.pivotWorld,
  });

  final Rect2D bounds;
  final List<Vec2> corners;
  final List<Vec2> handles;
  final Vec2 pivotWorld;
}

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
