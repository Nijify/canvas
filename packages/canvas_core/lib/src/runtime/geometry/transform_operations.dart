import 'package:canvas_core/src/foundation/core_types.dart' show Vec2;
import 'package:canvas_core/src/foundation/ids.dart' show ElementId;
import 'package:canvas_core/src/foundation/math/affine2d.dart';
import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/runtime/model/scene_document.dart';
import 'package:canvas_core/src/runtime/traversal/traversal.dart';

enum TransformSpace { local, parent, world }
enum TransformPreservation { local, world }

/// Geometry/resource/visibility-independent authored hierarchy lookup.
Affine2D? worldTransformOf(CanvasSceneDocument scene, ElementId id) {
  Affine2D? visit(Node node, Affine2D parent) {
    final world = parent * node.xf;
    if (node.id == id) return world;
    for (final child in node.childrenOrEmpty) {
      final found = visit(child, world);
      if (found != null) return found;
    }
    return null;
  }
  for (final root in scene.children) {
    final found = visit(root, const Affine2D.identity());
    if (found != null) return found;
  }
  return null;
}

Affine2D? parentWorldTransformOf(CanvasSceneDocument scene, ElementId id) {
  final ref = findParentOf(scene, id);
  if (ref == null) return null;
  return ref.parent == null ? const Affine2D.identity() : worldTransformOf(scene, ref.parent!.id);
}

/// Shared delta convention. A world operation needs only the parent's inverse,
/// so a singular selected node can still be moved under an invertible parent.
Affine2D transformAfterDelta(
  Affine2D local,
  Affine2D delta, {
  required TransformSpace space,
  Affine2D parentWorld = const Affine2D.identity(),
}) {
  switch (space) {
    case TransformSpace.local:
      return local * delta;
    case TransformSpace.parent:
      return delta * local;
    case TransformSpace.world:
      final inverse = parentWorld.tryInverse();
      if (inverse == null) throw StateError('Parent transform cannot be inverted reliably.');
      return inverse * delta * parentWorld * local;
  }
}

Affine2D affineAround(Vec2 anchor, Affine2D delta) =>
    Affine2D.translation(anchor.x, anchor.y) * delta *
    Affine2D.translation(-anchor.x, -anchor.y);
