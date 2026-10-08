import 'package:canvas_core/src/algorithms/export/content_bounds.dart'
    show computePaddedContentBounds;
import 'package:canvas_core/src/algorithms/export/content_bounds_policy.dart'
    show ContentBoundsSpec;
import 'package:canvas_core/src/algorithms/layout/computed_scene.dart'
    show ComputedScene, computeScene;
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;
import 'package:canvas_core/src/runtime/model/scene_document.dart'
    show CanvasSceneDocument;
import 'package:canvas_core/src/services/services_context.dart'
    show CoreServices;

/// An already-prepared scene and its derived geometry for painting and export.
class SceneEvaluation {
  const SceneEvaluation({
    required this.scene,
    required this.computed,
    required this.contentBounds,
  });

  final CanvasSceneDocument scene;
  final ComputedScene computed;
  final Rect2D? contentBounds;
}

/// Pure, synchronous transformation from one runtime scene to another.
typedef ScenePreparer =
    CanvasSceneDocument Function(
      CanvasSceneDocument scene,
      CoreServices services,
    );

/// Evaluate the prepared scene using the caller's stable service bundle.
///
/// The same [services] instance can be used by a [ScenePreparer] beforehand.
SceneEvaluation evaluateScene(
  CanvasSceneDocument preparedScene,
  CoreServices services, {
  ContentBoundsSpec? contentBounds,
}) {
  final computed = computeScene(preparedScene, services);
  final spec = contentBounds;
  final bounds = spec == null
      ? null
      : computePaddedContentBounds(
          scene: preparedScene,
          computed: computed,
          policy: spec.policy,
          paddingPx: spec.paddingPx,
        );

  return SceneEvaluation(
    scene: preparedScene,
    computed: computed,
    contentBounds: bounds,
  );
}
