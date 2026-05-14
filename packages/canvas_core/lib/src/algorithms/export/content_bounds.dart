// Path: lib/src/algorithms/export/content_bounds.dart

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
  Rect2D? b;

  final preferredId = policy.preferredIdFor(scene);
  if (preferredId != null) {
    b = computed.visualBoundsWorldById[preferredId];
  }

  b ??= selectionUnionBounds(
    policy.fallbackIdsFor(scene),
    getBounds: (id) => computed.visualBoundsWorldById[id],
  );

  if (b == null || b.width <= 0 || b.height <= 0) return null;

  final p = paddingPx;
  return Rect2D.fromLTWH(
    b.left - p,
    b.top - p,
    b.width + p * 2,
    b.height + p * 2,
  );
}
