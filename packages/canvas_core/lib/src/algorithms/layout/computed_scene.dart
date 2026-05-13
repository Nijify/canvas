// Path: oss_packages/canvas_core/lib/src/algorithms/layout/computed_scene.dart

import 'package:canvas_core/src/algorithms/layout/node_geometry.dart';
import 'package:canvas_core/src/runtime/traversal/stack_order.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/foundation/geometry/geometry.dart';
import 'package:canvas_core/src/foundation/geometry/geometry_ext.dart'
    show Rect2DX;
import 'package:canvas_core/src/foundation/math/affine2d.dart' show matFromTRS;

import 'package:canvas_core/src/services/services_context.dart'
    show CoreServices;
import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/runtime/model/scene_document.dart';
import 'package:canvas_core/src/runtime/geometry/scene_math.dart'
    show aabbOfTransformedRect;
import 'package:canvas_core/src/path/path_ir.dart' show PathIR;

final class DrawItem {
  final NodeId leafId;
  final List<NodeId> groupStack; // root..parent group ids
  const DrawItem({required this.leafId, required this.groupStack});
}

final class ImagePlacement {
  final Rect2D src;
  final Rect2D dst;
  const ImagePlacement({required this.src, required this.dst});
}

final class IconTextPayload {
  final String glyph;
  final String family;
  final int weight;
  const IconTextPayload({
    required this.glyph,
    required this.family,
    required this.weight,
  });
}

final class ComputedScene {
  final List<DrawItem> drawList;

  final Map<NodeId, Node> nodeById;

  final Map<NodeId, vm.Matrix4> worldById;
  final Map<NodeId, vm.Matrix4> inverseWorldById;

  final Map<NodeId, Rect2D> localBoundsById;
  final Map<NodeId, Rect2D> visualBoundsWorldById;

  final Map<NodeId, PathIR> pathIRById;
  final Map<NodeId, ImagePlacement> imagePlacementById;

  // icon pre-resolution (so paint is pure)
  final Map<NodeId, IconTextPayload> iconTextById;
  final Map<NodeId, PathIR> iconPathIRById;

  const ComputedScene({
    required this.drawList,
    required this.nodeById,
    required this.worldById,
    required this.inverseWorldById,
    required this.localBoundsById,
    required this.visualBoundsWorldById,
    required this.pathIRById,
    required this.imagePlacementById,
    required this.iconTextById,
    required this.iconPathIRById,
  });
}

Vec2 _pivotFromOrigin(OriginKind origin, Rect2D? b, Vec2? custom) {
  switch (origin) {
    case OriginKind.custom:
      return custom ?? const Vec2(0, 0);
    case OriginKind.center:
      if (b == null) return const Vec2(0, 0);
      return Vec2((b.left + b.right) * 0.5, (b.top + b.bottom) * 0.5);
  }
}

ComputedScene computeScene(CanvasSceneDocument doc, CoreServices services) {
  final geom = NodeGeometry(services);
  final drawList = <DrawItem>[];
  final nodeById = <NodeId, Node>{};

  final worldById = <NodeId, vm.Matrix4>{};
  final inverseWorldById = <NodeId, vm.Matrix4>{};

  final localBoundsById = <NodeId, Rect2D>{};
  final visualBoundsWorldById = <NodeId, Rect2D>{};

  final pathIRById = <NodeId, PathIR>{};
  final imagePlacementById = <NodeId, ImagePlacement>{};
  final iconTextById = <NodeId, IconTextPayload>{};
  final iconPathIRById = <NodeId, PathIR>{};

  // -----------------------------
  // Helpers
  // -----------------------------

  vm.Matrix4 localMatrixFromKnownBounds(Node n) {
    final xf = n.xf;
    final b = localBoundsById[n.id];
    final pivot = _pivotFromOrigin(xf.origin, b, xf.customPivotPx);

    return matFromTRS(
      position: xf.position,
      rotationRad: xf.rotationRad,
      scale: xf.scale,
      pivotPx: pivot,
    );
  }

  // -----------------------------
  // PASS A: compute localBounds for ALL nodes (leaves + groups)
  // - Leaves: measure/compile + cache
  // - Groups: union(children bounds transformed into this node's local space)
  // -----------------------------
  Rect2D? computeLocalBounds(Node n, bool ancestorHidden) {
    final hidden = ancestorHidden || n.hidden;
    if (hidden) return null;

    final leafBounds = geom.leafLocalBounds(
      n,
      pathIRById: pathIRById,
      imagePlacementById: imagePlacementById,
      iconTextById: iconTextById,
      iconPathIRById: iconPathIRById,
    );

    if (leafBounds != null) {
      localBoundsById[n.id] = leafBounds;
      return leafBounds;
    }

    // Group/logo bounds: union child AABBs in *this node's local space*.
    if (n is GroupNode) {
      Rect2D? u;

      final kids = nodesInPaintOrder(n.childrenOrEmpty);
      for (final c in kids) {
        final cb = computeLocalBounds(c, hidden);
        if (cb == null) continue;

        // Child local matrix uses child's own pivot rules, which rely on its bounds
        // (already computed because this is post-order).
        final childLocalMat = localMatrixFromKnownBounds(c);
        final childAabbInParentLocal = aabbOfTransformedRect(cb, childLocalMat);

        u = (u == null)
            ? childAabbInParentLocal
            : Rect2DX.union(u, childAabbInParentLocal);
      }

      if (u != null) localBoundsById[n.id] = u;
      return u;
    }

    return null;
  }

  // Run pass A for all roots
  for (final n in nodesInPaintOrder(doc.children)) {
    computeLocalBounds(n, false);
  }

  // -----------------------------
  // PASS B: compute world matrices + drawList + visual world bounds
  // -----------------------------
  Rect2D? walk(
    Node n,
    vm.Matrix4 parentWorld,
    List<NodeId> groupStack,
    bool ancestorHidden,
  ) {
    final hidden = ancestorHidden || n.hidden;
    if (hidden) return null;

    nodeById[n.id] = n;

    final localMat = localMatrixFromKnownBounds(n);
    final world = vm.Matrix4.copy(parentWorld)..multiply(localMat);

    worldById[n.id] = world;

    final inv = vm.Matrix4.copy(world)..invert();
    inverseWorldById[n.id] = inv;

    if (n is GroupNode) {
      final kids = nodesInPaintOrder(n.childrenOrEmpty);
      final nextStack = [...groupStack, n.id];

      Rect2D? groupWorld;
      for (final c in kids) {
        final cb = walk(c, world, nextStack, hidden);
        if (cb == null) continue;
        groupWorld = (groupWorld == null) ? cb : Rect2DX.union(groupWorld, cb);
      }

      if (groupWorld != null) {
        visualBoundsWorldById[n.id] = groupWorld;
      }
      return groupWorld;
    }

    // Leaf: add draw item
    drawList.add(DrawItem(leafId: n.id, groupStack: groupStack));

    final lb = localBoundsById[n.id];
    if (lb != null) {
      final aabb = aabbOfTransformedRect(lb, world);
      visualBoundsWorldById[n.id] = aabb;
      return aabb;
    }

    return null;
  }

  for (final n in nodesInPaintOrder(doc.children)) {
    walk(n, vm.Matrix4.identity(), const <NodeId>[], false);
  }

  return ComputedScene(
    drawList: drawList,
    nodeById: nodeById,
    worldById: worldById,
    inverseWorldById: inverseWorldById,
    localBoundsById: localBoundsById,
    visualBoundsWorldById: visualBoundsWorldById,
    pathIRById: pathIRById,
    imagePlacementById: imagePlacementById,
    iconTextById: iconTextById,
    iconPathIRById: iconPathIRById,
  );
}
