// Path: packages/canvas_core/lib/src/algorithms/export/content_bounds.dart

import 'package:canvas_core/src/algorithms/export/content_bounds_policy.dart'
    show ContentBoundsPolicy;
import 'package:canvas_core/src/algorithms/layout/computed_scene.dart'
    show ComputedScene;
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;
import 'package:canvas_core/src/foundation/geometry/geometry_ext.dart'
    show Rect2DX;
import 'package:canvas_core/src/foundation/ids.dart' show ElementId;
import 'package:canvas_core/src/runtime/model/scene_document.dart';

Rect2D? _unionPaintBounds(Iterable<ElementId> ids, ComputedScene computed) {
  Rect2D? result;

  for (final id in ids) {
    final bounds = computed.paintBoundsWorldById[id];
    if (bounds == null) continue;

    result = result == null ? bounds : Rect2DX.union(result, bounds);
  }

  return result;
}

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

  bounds ??= _unionPaintBounds(policy.fallbackIdsFor(scene), computed);

  if (bounds == null || bounds.width <= 0 || bounds.height <= 0) {
    return null;
  }

  return Rect2D.fromLTWH(
    bounds.left - paddingPx,
    bounds.top - paddingPx,
    bounds.width + paddingPx * 2,
    bounds.height + paddingPx * 2,
  );
}
