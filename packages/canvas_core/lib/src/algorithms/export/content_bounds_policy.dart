// Path: oss_packages/canvas_core/lib/src/algorithms/export/content_bounds_policy.dart

import 'package:canvas_core/src/foundation/ids.dart' show ElementId;
import 'package:canvas_core/src/runtime/model/scene_document.dart'
    show CanvasSceneDocument;

typedef ContentBoundsElementSelector =
    ElementId? Function(CanvasSceneDocument scene);

typedef ContentBoundsFallbackSelector =
    Iterable<ElementId> Function(CanvasSceneDocument scene);

/// Generic runtime policy for content-bounds calculations.
///
/// This is intentionally product agnostic.
/// Host applications may prefer a semantic root, while the base runtime falls
/// back to root scene children.
class ContentBoundsPolicy {
  const ContentBoundsPolicy({this.preferredElementId, this.fallbackElementIds});

  /// Optional preferred root used for content-bounds fit/crop/thumb/export.
  ///
  /// Host applications can provide a preferred semantic root.
  final ContentBoundsElementSelector? preferredElementId;

  /// Optional fallback ids when the preferred element is absent or has no bounds.
  ///
  /// Null means use scene root children.
  final ContentBoundsFallbackSelector? fallbackElementIds;

  ElementId? preferredIdFor(CanvasSceneDocument scene) {
    return preferredElementId?.call(scene);
  }

  Iterable<ElementId> fallbackIdsFor(CanvasSceneDocument scene) {
    return fallbackElementIds?.call(scene) ?? scene.children.map((n) => n.id);
  }
}

/// Runtime-owned spec for custom content-bounds computation.
///
/// A null ContentBoundsSpec means content-bounds are disabled.
class ContentBoundsSpec {
  const ContentBoundsSpec({
    this.paddingPx = 0,
    this.policy = const ContentBoundsPolicy(),
  });

  final double paddingPx;
  final ContentBoundsPolicy policy;
}
