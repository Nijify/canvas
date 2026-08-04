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

/// Shared render-builder seam used by editors, thumbnails, exporters,
/// and extension packages.
///
/// The input scene is a runtime scene that is ready for this builder's
/// preparation/rendering rules. The default builder renders it directly.
/// Custom builders may prepare it further before delegating to the runtime
/// pipeline.
typedef SceneRenderBuilder =
    RenderSnapshot Function(
      CanvasRenderPipeline pipeline,
      CanvasSceneDocument scene, {
      ContentBoundsSpec? contentBounds,
    });

/// Default generic runtime render builder.
///
/// Does not know about application-provided behavior.
RenderSnapshot defaultSceneRenderBuilder(
  CanvasRenderPipeline pipeline,
  CanvasSceneDocument scene, {
  ContentBoundsSpec? contentBounds,
}) {
  return pipeline.build(scene, contentBounds: contentBounds);
}

/// Reusable runtime render pipeline.
///
/// Runtime renders a prepared [CanvasSceneDocument]. Domain-specific extensions
/// should prepare their scenes before calling this pipeline, or expose their own
/// wrapper extension from their package.
class CanvasRenderPipeline {
  CanvasRenderPipeline({
    required TextMeasurer textMeasurer,
    ImageIntrinsics? images,
    IconResolver? icons,
  }) : _textMeasurer = textMeasurer,
       _images = images,
       _icons = icons;

  final TextMeasurer _textMeasurer;
  final ImageIntrinsics? _images;
  final IconResolver? _icons;

  /// Builds the service bundle used by runtime compute and paint planning.
  ///
  /// Extension packages can use this to prepare a scene with exactly the same
  /// service dependencies before delegating back to [build].
  CoreServices createServices() {
    return CoreServices(tm: _textMeasurer, images: _images, icons: _icons);
  }

  RenderSnapshot build(
    CanvasSceneDocument scene, {
    ContentBoundsSpec? contentBounds,
  }) {
    final services = createServices();

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
