// Path: packages/canvas_core/lib/src/algorithms/layout/computed_scene.dart

import 'package:canvas_core/src/algorithms/layout/image_fit.dart'
    show ImagePlacement;
import 'package:canvas_core/src/algorithms/layout/node_geometry.dart';
import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/foundation/geometry/geometry.dart';
import 'package:canvas_core/src/foundation/geometry/geometry_ext.dart'
    show Rect2DX;
import 'package:canvas_core/src/foundation/ids.dart' show ElementId;
import 'package:canvas_core/src/foundation/math/affine2d.dart' show matFromTRS;
import 'package:canvas_core/src/path/path_ir.dart' show PathIR;
import 'package:canvas_core/src/runtime/geometry/scene_math.dart'
    show aabbOfTransformedRect;
import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/runtime/model/scene_document.dart';
import 'package:canvas_core/src/runtime/traversal/stack_order.dart';
import 'package:canvas_core/src/services/icon_resolver.dart'
    show ResolvedIconText;
import 'package:canvas_core/src/services/services_context.dart'
    show CoreServices;
import 'package:vector_math/vector_math_64.dart' as vm;

final class DrawItem {
  final ElementId leafId;
  final List<ElementId> groupStack;

  const DrawItem({required this.leafId, required this.groupStack});
}

/// Computed document/render geometry in document units; these maps are not
/// serialized.
///
/// Local layout bounds determine pivots and authored transform semantics.
/// Paint bounds estimate rendered content for fitting and cropping; they must
/// not affect transforms. Text metrics and the existing path-stroke estimate
/// are not guaranteed pixel enclosures, so these are not hard clip bounds.
///
/// Groups union child bounds independently in local layout space and world
/// paint space. Editor-only world interaction geometry is derived by
/// `canvas_editor_flutter`.
final class ComputedScene {
  final List<DrawItem> drawList;
  final Map<ElementId, Node> nodeById;
  final Map<ElementId, vm.Matrix4> worldById;

  final Map<ElementId, Rect2D> layoutBoundsLocalById;
  final Map<ElementId, Rect2D> paintBoundsLocalById;
  final Map<ElementId, Rect2D> paintBoundsWorldById;

  final Map<ElementId, PathIR> pathIRById;
  final Map<ElementId, ImagePlacement> imagePlacementById;
  final Map<ElementId, ResolvedIconText> iconTextById;
  final Map<ElementId, PathIR> iconPathIRById;

  const ComputedScene({
    required this.drawList,
    required this.nodeById,
    required this.worldById,
    required this.layoutBoundsLocalById,
    required this.paintBoundsLocalById,
    required this.paintBoundsWorldById,
    required this.pathIRById,
    required this.imagePlacementById,
    required this.iconTextById,
    required this.iconPathIRById,
  });
}

Vec2 _pivotFromOrigin(OriginKind origin, Rect2D? bounds, Vec2? custom) {
  switch (origin) {
    case OriginKind.custom:
      return custom ?? const Vec2(0, 0);
    case OriginKind.center:
      if (bounds == null) return const Vec2(0, 0);
      return Vec2(
        (bounds.left + bounds.right) * 0.5,
        (bounds.top + bounds.bottom) * 0.5,
      );
  }
}

ComputedScene computeScene(CanvasSceneDocument doc, CoreServices services) {
  final geom = NodeGeometry(services);
  final drawList = <DrawItem>[];
  final nodeById = <ElementId, Node>{};
  final worldById = <ElementId, vm.Matrix4>{};

  final layoutBoundsLocalById = <ElementId, Rect2D>{};
  final paintBoundsLocalById = <ElementId, Rect2D>{};
  final paintBoundsWorldById = <ElementId, Rect2D>{};

  final pathIRById = <ElementId, PathIR>{};
  final imagePlacementById = <ElementId, ImagePlacement>{};
  final iconTextById = <ElementId, ResolvedIconText>{};
  final iconPathIRById = <ElementId, PathIR>{};

  vm.Matrix4 localMatrixFromLayout(Node n) {
    final xf = n.xf;
    final pivot = _pivotFromOrigin(
      xf.origin,
      layoutBoundsLocalById[n.id],
      xf.customPivotPx,
    );
    return matFromTRS(
      position: xf.position,
      rotationRad: xf.rotationRad,
      scale: xf.scale,
      pivotPx: pivot,
    );
  }

  // Post-order: resolve each leaf once, then aggregate local layout/paint
  // bounds. A child's layout is settled before its transform is used by its
  // parent.
  void computeLocalBounds(Node n) {
    if (n.hidden) return;

    final leaf = geom.leafBounds(
      n,
      pathIRById: pathIRById,
      imagePlacementById: imagePlacementById,
      iconTextById: iconTextById,
      iconPathIRById: iconPathIRById,
    );
    if (leaf != null) {
      layoutBoundsLocalById[n.id] = leaf.layout;
      final paint = leaf.paint;
      if (paint != null) paintBoundsLocalById[n.id] = paint;
      return;
    }
    if (n is! GroupNode) return;

    Rect2D? layoutUnion;
    Rect2D? paintUnion;

    for (final child in nodesInPaintOrder(n.children)) {
      computeLocalBounds(child);

      final layout = layoutBoundsLocalById[child.id];
      final paint = paintBoundsLocalById[child.id];

      if (layout == null && paint == null) continue;

      final childLocal = localMatrixFromLayout(child);

      if (layout != null) {
        final transformed = aabbOfTransformedRect(layout, childLocal);
        layoutUnion = layoutUnion == null
            ? transformed
            : Rect2DX.union(layoutUnion, transformed);
      }

      if (paint != null) {
        final transformed = aabbOfTransformedRect(paint, childLocal);
        paintUnion = paintUnion == null
            ? transformed
            : Rect2DX.union(paintUnion, transformed);
      }
    }

    if (layoutUnion != null) {
      layoutBoundsLocalById[n.id] = layoutUnion;
    }

    if (paintUnion != null) {
      paintBoundsLocalById[n.id] = paintUnion;
    }
  }

  for (final root in nodesInPaintOrder(doc.children)) {
    computeLocalBounds(root);
  }

  // Pre-order transforms, followed by child-world paint unions for groups.
  //
  // Do not transform a group's already-aggregated local paint AABB again:
  // unioning child world paint bounds remains tighter under nested/counter
  // rotations.
  void walk(Node n, vm.Matrix4 parentWorld, List<ElementId> groupStack) {
    if (n.hidden) return;

    nodeById[n.id] = n;

    final world = vm.Matrix4.copy(parentWorld)
      ..multiply(localMatrixFromLayout(n));

    worldById[n.id] = world;

    if (n is GroupNode) {
      final nextStack = [...groupStack, n.id];
      Rect2D? paintUnion;

      for (final child in nodesInPaintOrder(n.children)) {
        walk(child, world, nextStack);

        final paint = paintBoundsWorldById[child.id];
        if (paint != null) {
          paintUnion = paintUnion == null
              ? paint
              : Rect2DX.union(paintUnion, paint);
        }
      }

      if (paintUnion != null) {
        paintBoundsWorldById[n.id] = paintUnion;
      }

      return;
    }

    drawList.add(DrawItem(leafId: n.id, groupStack: groupStack));

    final paint = paintBoundsLocalById[n.id];

    if (paint != null) {
      paintBoundsWorldById[n.id] = aabbOfTransformedRect(paint, world);
    }
  }

  for (final root in nodesInPaintOrder(doc.children)) {
    walk(root, vm.Matrix4.identity(), const <ElementId>[]);
  }

  return ComputedScene(
    drawList: drawList,
    nodeById: nodeById,
    worldById: worldById,
    layoutBoundsLocalById: layoutBoundsLocalById,
    paintBoundsLocalById: paintBoundsLocalById,
    paintBoundsWorldById: paintBoundsWorldById,
    pathIRById: pathIRById,
    imagePlacementById: imagePlacementById,
    iconTextById: iconTextById,
    iconPathIRById: iconPathIRById,
  );
}
