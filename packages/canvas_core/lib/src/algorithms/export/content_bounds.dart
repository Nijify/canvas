import 'package:canvas_core/src/algorithms/export/content_bounds_policy.dart'
    show ContentBoundsPolicy;
import 'package:canvas_core/src/algorithms/layout/computed_scene.dart'
    show ComputedScene;
import 'package:canvas_core/src/algorithms/layout/selection_geometry.dart';
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;
import 'package:canvas_core/src/runtime/model/scene_document.dart';

Rect2D? computePaddedContentBounds({
  required CanvasSceneDocument scene,
  required ComputedScene computed,
  ContentBoundsPolicy policy = const ContentBoundsPolicy(),
  double paddingPx = 0,
}) {
  Rect2D? bounds;
  final preferredId = policy.preferredIdFor(scene);
  if (preferredId != null) {
    bounds = computed.paintBoundsWorldById[preferredId];
  }

  bounds ??= selectionUnionBounds(
    policy.fallbackIdsFor(scene),
    getBounds: (id) => computed.paintBoundsWorldById[id],
  );
  if (bounds == null || bounds.width <= 0 || bounds.height <= 0) return null;

  return Rect2D.fromLTWH(
    bounds.left - paddingPx,
    bounds.top - paddingPx,
    bounds.width + paddingPx * 2,
    bounds.height + paddingPx * 2,
  );
}
