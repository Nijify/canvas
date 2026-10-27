import 'package:canvas_core/src/runtime/validation/scene_document_validation.dart';
// Path: packages/canvas_core/lib/src/algorithms/layout/computed_scene.dart

import 'package:canvas_core/src/algorithms/layout/image_fit.dart'
    show ImagePlacement;
import 'package:canvas_core/src/algorithms/layout/computed_icon.dart'
    show ComputedIcon;
import 'package:canvas_core/src/algorithms/layout/node_geometry.dart';

import 'package:canvas_core/src/foundation/geometry/geometry.dart';
import 'package:canvas_core/src/foundation/geometry/geometry_ext.dart'
    show Rect2DX;
import 'package:canvas_core/src/foundation/ids.dart' show ElementId;
import 'package:canvas_core/src/foundation/math/affine2d.dart' show Affine2D;
import 'package:canvas_core/src/path/path_ir.dart' show PathIR;
import 'package:canvas_core/src/runtime/geometry/scene_math.dart'
    show aabbOfTransformedRect;
import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/runtime/model/scene_document.dart';
import 'package:canvas_core/src/runtime/traversal/stack_order.dart';
import 'package:canvas_core/src/services/services_context.dart'
    show CoreServices;


final class DrawItem {
  final ElementId leafId;
  final List<ElementId> groupStack;

  const DrawItem({required this.leafId, required this.groupStack});
}

/// Computed document/render geometry in document units; these maps are not
/// serialized.
///
/// Authored transforms are independent of all geometry and appearance bounds.
/// Paths use geometry alone, retaining zero-width or zero-height bounds.
/// Paint bounds estimate rendered content for fitting and cropping; they must
/// not affect transforms. Path stroke bounds conservatively include caps and
/// joins. Text metrics, blur tails, and raster antialiasing are estimates or
/// export padding policies, so these are not hard clip bounds.
///
/// Groups union child bounds independently in local layout space and world
/// paint space. Editor-only world interaction geometry is derived by
/// `canvas_editor_flutter`.
final class ComputedScene {
  final List<DrawItem> drawList;
  final Map<ElementId, Node> nodeById;
  final Map<ElementId, Affine2D> worldById;

  final Map<ElementId, Rect2D> layoutBoundsLocalById;
  final Map<ElementId, Rect2D> paintBoundsLocalById;
  final Map<ElementId, Rect2D> paintBoundsWorldById;

  final Map<ElementId, PathIR> pathIRById;
  final Map<ElementId, ImagePlacement> imagePlacementById;
  final Map<ElementId, ComputedIcon> iconById;

  const ComputedScene._({
    required this.drawList,
    required this.nodeById,
    required this.worldById,
    required this.layoutBoundsLocalById,
    required this.paintBoundsLocalById,
    required this.paintBoundsWorldById,
    required this.pathIRById,
    required this.imagePlacementById,
    required this.iconById,
  });
}

ComputedScene computeScene(CanvasSceneDocument doc, CoreServices services) {
  requireCanvasSceneIntegrity(doc);
  final geometry = NodeGeometry(services);
  final drawList = <DrawItem>[];
  final nodes = <ElementId, Node>{};
  final worlds = <ElementId, Affine2D>{};
  final layouts = <ElementId, Rect2D>{};
  final paints = <ElementId, Rect2D>{};
  final worldPaints = <ElementId, Rect2D>{};
  final paths = <ElementId, PathIR>{};
  final images = <ElementId, ImagePlacement>{};
  final icons = <ElementId, ComputedIcon>{};

  Rect2D union(Rect2D? current, Rect2D value) =>
      current == null ? value : Rect2DX.union(current, value);

  // World matrices are settled on entry. Group bounds are aggregated on return.
  // Hidden nodes retain hierarchy transforms without resolving their resources.
  void visit(Node node, Affine2D parent, List<ElementId> ancestors, bool hidden) {
    final world = parent * node.xf;
    nodes[node.id] = node;
    worlds[node.id] = world;
    final invisible = hidden || node.hidden;
    if (node is GroupNode) {
      Rect2D? layout, paint, worldPaint;
      final stack = List<ElementId>.unmodifiable([...ancestors, node.id]);
      for (final child in nodesInPaintOrder(node.children)) {
        visit(child, world, stack, invisible);
        final childLayout = layouts[child.id];
        final childPaint = paints[child.id];
        final childWorldPaint = worldPaints[child.id];
        if (childLayout != null) {
          layout = union(layout, aabbOfTransformedRect(childLayout, child.xf));
        }
        if (childPaint != null) {
          paint = union(paint, aabbOfTransformedRect(childPaint, child.xf));
        }
        if (childWorldPaint != null) worldPaint = union(worldPaint, childWorldPaint);
      }
      if (layout != null) layouts[node.id] = layout;
      if (paint != null) paints[node.id] = paint;
      // Keep tight child-world unions instead of transforming group AABBs again.
      if (worldPaint != null) worldPaints[node.id] = worldPaint;
      return;
    }
    if (invisible) return;
    final bounds = geometry.leafBounds(
      node, pathIRById: paths, imagePlacementById: images, iconById: icons,
    );
    if (bounds != null) {
      layouts[node.id] = bounds.layout;
      // Validate layout coordinates too, including unpainted selection geometry.
      aabbOfTransformedRect(bounds.layout, world);
      if (bounds.paint != null) {
        paints[node.id] = bounds.paint!;
        worldPaints[node.id] = aabbOfTransformedRect(bounds.paint!, world);
      }
    }
    drawList.add(DrawItem(leafId: node.id, groupStack: ancestors));
  }

  for (final root in nodesInPaintOrder(doc.children)) {
    visit(root, const Affine2D.identity(), const [], false);
  }
  return ComputedScene._(
    drawList: List.unmodifiable(drawList),
    nodeById: Map.unmodifiable(nodes), worldById: Map.unmodifiable(worlds),
    layoutBoundsLocalById: Map.unmodifiable(layouts),
    paintBoundsLocalById: Map.unmodifiable(paints),
    paintBoundsWorldById: Map.unmodifiable(worldPaints),
    pathIRById: Map.unmodifiable(paths),
    imagePlacementById: Map.unmodifiable(images), iconById: Map.unmodifiable(icons),
  );
}
