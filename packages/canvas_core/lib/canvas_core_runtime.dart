// Path: oss_packages/canvas_core/lib/canvas_core_runtime.dart
//
// canvas_core_runtime – Public RUNTIME API (generic core / source of truth)
//
// Mental model:
// Runtime is the “real scene + behavior” layer for the generic canvas engine.
// It defines the concrete scene objects and everything needed to operate/render
// them in a renderer-agnostic way (scene model, compute, paint ops, geometry,
// traversal, and host service contracts).
//
// Dependency direction:
//   • Editor helpers build ON TOP of runtime.
//   • Extension packages build ON TOP of runtime and should NOT be
//     required by core consumers.
//
// External packages (renderers/apps) should import this file when they need the
// generic runtime surface.
//
// Generic runtime pipeline:
//   computeScene(scene, services) → buildPaintOpsFromScene(scene, computed)
//
// Canonical pipeline guidance:
//   • Core-safe canonical helper:
//       CanvasRenderPipeline.buildCanonical(...)
//     This renders an already-prepared runtime scene and does NOT hardcode
//     application-provided behavior.
//
// Prefer consuming ComputedScene (drawList/world matrices/bounds) in higher-level
// subsystems instead of recomputing transforms/bounds independently.
//
// This file intentionally does NOT export editor interaction helpers
// (undo/pick/snap); use canvas_core_editor.dart for those.
// ─────────────────────────────────────────────────────────────────────────────

// ============================================================================
// 2) Runtime models (scene graph)
// ============================================================================
export 'src/runtime/model/scene_document.dart';
export 'src/runtime/model/node_model.dart'
    show
        Node,
        TextNode,
        IconNode,
        ImageNode,
        PathNode,
        GroupNode,
        NodeId,
        OriginKind,
        Transform2D,
        GroupBehaviorRef,
        TextData,
        CanvasIconData,
        ImageData,
        ImageFit,
        PathData,
        NodeFields;

// ============================================================================
// 3) Compute / geometry helpers
// ============================================================================
export 'src/algorithms/layout/computed_scene.dart'
    show ComputedScene, DrawItem, ImagePlacement, IconTextPayload, computeScene;
export 'src/algorithms/layout/node_geometry.dart' show NodeGeometry;

// ============================================================================
// 4) Paint plan / IR (renderer-agnostic drawing plan)
// ============================================================================
export 'src/render_plan/paint_ops.dart';
export 'src/render_plan/op_builder_scene.dart' show buildPaintOpsFromScene;

export 'src/render_plan/gradient_resolver.dart'
    show ResolvedLinearGradient, resolveLinearGradient;

// Shared style enums (used by models and IR)
export 'src/foundation/style/style_types.dart'
    show FillRule, StrokeCap, StrokeJoin;

// Path IR + declarative sources (runtime reads these; compilation is internal)
export 'src/path/path_ir.dart' show PathCmd, PathIR, PathStyle, PathVerb;
export 'src/path/path_source.dart'
    show
        PathSource,
        PolylineSource,
        RectSource,
        RoundRectSource,
        PillSource,
        UnderlineSource,
        EllipseSource,
        CircleSource,
        RegularPolygonSource,
        StarSource,
        SvgPathSource;

// ============================================================================
// 5) Geometry primitives + derived helpers (renderer-agnostic)
// ============================================================================

export 'src/foundation/core_types.dart'
    show Color32, LinearGradientSpec, Size2D, Vec2, FontWeightNum;
export 'src/foundation/assets/canvas_asset_ref.dart'
    show
        CanvasAssetRef,
        CanvasSchemeAssetRef,
        CanvasUrlAssetRef,
        CanvasDataUriAssetRef,
        CanvasBlobUrlAssetRef,
        CanvasFileAssetRef,
        CanvasRawAssetRef,
        parseCanvasAssetRef;
export 'src/foundation/geometry/geometry.dart' show Rect2D;
export 'src/foundation/geometry/geometry_ext.dart';
export 'src/foundation/ids.dart' show ElementId;

// Derived geometry helpers (selection bounds, unions)
export 'src/algorithms/layout/selection_geometry.dart'
    show selectionGeometry, selectionUnionBounds;

// Text measure helpers/caches (service-facing)
export 'src/services/text_measure.dart' show spacedText, TextMeasureCache;

// ============================================================================
// 7) Serde (JSON I/O boundary) + host service contracts
// ============================================================================
export 'src/serialization/serializers.dart';

export 'src/services/services.dart' show ImageIntrinsics, TextMeasurer;
export 'src/services/services_context.dart' show CoreServices;

export 'src/services/icon_resolver.dart'
    show IconResolver, ResolvedIcon, ResolvedIconText, ResolvedIconPath;

// ============================================================================
// 8) Traversal / query helpers (headless, deterministic)
// ============================================================================
export 'src/runtime/traversal/traversal.dart'
    show findById, findParentOf, visitSceneNodes, collectAllNodeIds;
export 'src/runtime/traversal/rewrite.dart'
    show replaceById, rewriteSceneDocument, rewritePostOrder;
// TODO(api): Promote this to a stable public NodeEditingX API.
// Currently exported so external packages can immutably edit generic Node
// fields without importing package:canvas_core/src/...
// Before stabilizing:
// - rename node_mutations.dart → node_editing.dart
// - rename NodeMutations → NodeEditingX
// - expose only safe helpers: withXf, withHidden, withName, withLocked
// - stacking is controlled by sibling order, not a stored zIndex field
// - reconsider whether withId and withChildren should remain public
export 'src/runtime/model/node_mutations.dart' show NodeMutations;
export 'src/runtime/traversal/scene_tree_ops.dart' show SceneTreeOps;
export 'src/runtime/traversal/stack_order.dart'
    show nodesInPaintOrder, nodesInFrontToBackOrder;

// ============================================================================
// 9) Viewport + export helpers (renderer-agnostic)
// ============================================================================
export 'src/algorithms/viewport/viewport_math.dart'
    show
        CanvasFit,
        CanvasViewportTransform,
        computeViewport,
        computeViewportWithPadding;

// Crop-to-content / content bounds helpers
export 'src/algorithms/export/content_bounds_policy.dart'
    show
        ContentBoundsPolicy,
        ContentBoundsSpec,
        ContentBoundsElementSelector,
        ContentBoundsFallbackSelector;

export 'src/algorithms/export/content_bounds.dart'
    show computePaddedContentBounds;

export 'src/runtime/viewport/canvas_viewport_policy.dart'
    show CanvasViewportPolicy, CanvasViewportSource;

// ============================================================================
// 10) Misc paint helpers
// ============================================================================
export 'src/foundation/paint/canvas_fill.dart';

// ============================================================================
// 11) Runtime render pipeline
// ============================================================================
//
// NOTE:
// The generic runtime surface lives here.
//
// Exported here:
//   • CanvasRenderPipeline
//   • RenderSnapshot
//   • ContentBoundsSpec
//   • core-safe buildCanonical(...)
////
//// NOT exported here:
////   • domain-specific policy bundles
////   • application-provided render helpers
//// Domain-specific helpers should live outside this runtime barrel.
export 'src/runtime/render/canvas_render_pipeline.dart';

export 'src/runtime/viewport/canvas_viewport_planner.dart';
