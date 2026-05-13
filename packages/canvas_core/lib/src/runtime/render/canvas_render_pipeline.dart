// Path: oss_packages/canvas_core/lib/src/runtime/render/canvas_render_pipeline.dart

import 'package:canvas_core/src/algorithms/layout/computed_scene.dart'
    show computeScene, ComputedScene;
import 'package:canvas_core/src/algorithms/export/content_bounds.dart'
    show computePaddedContentBounds;
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
import 'package:canvas_core/src/services/text_measure.dart'
    show TextMeasureCache;
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;
import 'package:canvas_core/src/algorithms/export/content_bounds_policy.dart'
    show ContentBoundsSpec;

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
      TextMeasureCache? textMeasureCache,
    });

/// Default generic runtime render builder.
///
/// Does not know about application-provided behavior.
RenderSnapshot defaultSceneRenderBuilder(
  CanvasRenderPipeline pipeline,
  CanvasSceneDocument scene, {
  ContentBoundsSpec? contentBounds,
  TextMeasureCache? textMeasureCache,
}) {
  return pipeline.build(
    scene,
    contentBounds: contentBounds,
    textMeasureCache: textMeasureCache,
  );
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
  CoreServices createServices({TextMeasureCache? textMeasureCache}) {
    return CoreServices(
      tm: _textMeasurer,
      images: _images,
      icons: _icons,
      textMeasureCache: textMeasureCache ?? TextMeasureCache(),
    );
  }

  RenderSnapshot build(
    CanvasSceneDocument scene, {
    ContentBoundsSpec? contentBounds,

    /// Optional: inject a per-batch cache to avoid allocations.
    TextMeasureCache? textMeasureCache,
  }) {
    final services = createServices(textMeasureCache: textMeasureCache);

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

/// Compatibility helper for the generic runtime surface.
///
/// Guarantees:
/// - renders an already-prepared runtime scene
/// - no hard dependency on extension packages
///
/// Prefer [build] or [defaultSceneRenderBuilder] in new code. Extension
/// packages should layer on top of this via extension methods from their own
/// public barrels.
extension CanvasRenderPipelineCanonical on CanvasRenderPipeline {
  RenderSnapshot buildCanonical(
    CanvasSceneDocument scene, {
    ContentBoundsSpec? contentBounds,
    TextMeasureCache? textMeasureCache,
  }) {
    return build(
      scene,
      contentBounds: contentBounds,
      textMeasureCache: textMeasureCache,
    );
  }
}
