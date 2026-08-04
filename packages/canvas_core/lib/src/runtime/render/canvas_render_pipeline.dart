// Path: lib/src/runtime/render/canvas_render_pipeline.dart

import 'package:canvas_core/src/algorithms/export/content_bounds.dart'
    show computePaddedContentBounds;
import 'package:canvas_core/src/algorithms/export/content_bounds_policy.dart'
    show ContentBoundsSpec;
import 'package:canvas_core/src/algorithms/layout/computed_scene.dart'
    show ComputedScene, computeScene;
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;
import 'package:canvas_core/src/render_plan/op_builder_scene.dart'
    show buildPaintOpsFromScene;
import 'package:canvas_core/src/render_plan/paint_ops.dart' show PaintOp;
import 'package:canvas_core/src/runtime/model/scene_document.dart'
    show CanvasSceneDocument;
import 'package:canvas_core/src/services/icon_resolver.dart' show IconResolver;
import 'package:canvas_core/src/services/services.dart'
    show ImageIntrinsics, TextMeasurer;
import 'package:canvas_core/src/services/services_context.dart'
    show CoreServices;

/// Runtime render snapshot.
class RenderSnapshot {
  const RenderSnapshot({
    required this.scene,
    required this.computed,
    required this.ops,
    required this.contentBounds,
  });

  final CanvasSceneDocument scene;
  final ComputedScene computed;
  final List<PaintOp> ops;
  final Rect2D? contentBounds;
}

/// Pure, synchronous transformation from one runtime scene to another.
///
/// Preparers may apply domain-specific layout or placement policy, but do not
/// compute paint operations or construct a [RenderSnapshot].
typedef ScenePreparer =
    CanvasSceneDocument Function(
      CanvasSceneDocument scene,
      CoreServices services,
    );

/// Reusable runtime render pipeline.
///
/// Runtime renders an already-prepared [CanvasSceneDocument]. Domain-specific
/// preparation belongs outside this class and may use [services] before
/// delegating the prepared scene to [build].
class CanvasRenderPipeline {
  CanvasRenderPipeline({
    required TextMeasurer textMeasurer,
    ImageIntrinsics? images,
    IconResolver? icons,
  }) : services = CoreServices(tm: textMeasurer, images: images, icons: icons);

  /// Stable service bundle shared by scene preparation and final rendering.
  ///
  /// The same instance is retained for the lifetime of this pipeline.
  final CoreServices services;

  RenderSnapshot build(
    CanvasSceneDocument scene, {
    ContentBoundsSpec? contentBounds,
  }) {
    final computed = computeScene(scene, services);
    final ops = buildPaintOpsFromScene(scene, computed);

    Rect2D? bounds;
    final spec = contentBounds;

    if (spec != null) {
      bounds = computePaddedContentBounds(
        scene: scene,
        computed: computed,
        policy: spec.policy,
        paddingPx: spec.paddingPx,
      );
    }

    return RenderSnapshot(
      scene: scene,
      computed: computed,
      ops: ops,
      contentBounds: bounds,
    );
  }
}
