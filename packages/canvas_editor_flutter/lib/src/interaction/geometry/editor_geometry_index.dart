// Path: packages/canvas_editor_flutter/lib/src/interaction/geometry/editor_geometry_index.dart

import 'package:canvas_core/canvas_core_runtime.dart'
    show ComputedScene, ElementId, Rect2D, Rect2DX, aabbOfTransformedRect;
import 'package:vector_math/vector_math_64.dart' as vm;

/// Editor-owned geometry derived from core document/render computation.
///
/// These values exist for interaction concerns such as picking, snapping,
/// and drag probes. They are deliberately not part of `ComputedScene`.
final class EditorGeometryIndex {
  const EditorGeometryIndex({
    required this.inverseWorldById,
    required this.layoutBoundsWorldById,
  });

  final Map<ElementId, vm.Matrix4> inverseWorldById;
  final Map<ElementId, Rect2D> layoutBoundsWorldById;

  factory EditorGeometryIndex.fromComputed(ComputedScene computed) {
    final inverseWorldById = <ElementId, vm.Matrix4>{};
    final layoutBoundsWorldById = <ElementId, Rect2D>{};

    // Preserve the former ComputedScene inverse semantics exactly.
    for (final entry in computed.worldById.entries) {
      final inverse = vm.Matrix4.copy(entry.value)..invert();
      inverseWorldById[entry.key] = inverse;
    }

    // Derive leaf world-layout AABBs from canonical local layout bounds and
    // world transforms.
    //
    // Each leaf then contributes the same world rect to every group in its
    // ancestry. This intentionally preserves the former tight group-world
    // union behavior. Do not transform a group's already-aggregated local AABB.
    for (final item in computed.drawList) {
      final leafId = item.leafId;
      final local = computed.layoutBoundsLocalById[leafId];
      final world = computed.worldById[leafId];

      if (local == null || world == null) continue;

      final leafWorld = aabbOfTransformedRect(local, world);

      layoutBoundsWorldById[leafId] = leafWorld;

      for (final groupId in item.groupStack) {
        final previous = layoutBoundsWorldById[groupId];

        layoutBoundsWorldById[groupId] = previous == null
            ? leafWorld
            : Rect2DX.union(previous, leafWorld);
      }
    }

    return EditorGeometryIndex(
      inverseWorldById: inverseWorldById,
      layoutBoundsWorldById: layoutBoundsWorldById,
    );
  }
}
