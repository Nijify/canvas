// Path: lib/src/services/services.dart

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/foundation/ids.dart';

/// Synchronous text measurement used by core scene computation.
///
/// Implementations own any platform-specific layout and caching behavior.
abstract interface class TextMeasurer {
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  });
}

/// Synchronous intrinsic-image lookup used by core scene computation.
///
/// Resource loading and change notifications belong to the host/runtime layer.
/// Core only needs the latest intrinsic size available for an [ElementId].
abstract interface class ImageIntrinsics {
  Size2D? intrinsicSize(ElementId id);
}

/// Resolves durable canvas image source references for the current host.
///
/// Canvas documents store opaque logical `sourceRef` values. Implementations
/// translate those values into source references that the current rendering
/// host can load.
///
/// A resolved source is not necessarily a URL. Depending on the host it may be
/// an `https:`, `data:`, `blob:`, `asset:`, `file:`, or another renderable
/// source reference.
///
/// Returned maps may be partial. A missing entry means the source or metadata
/// could not be resolved.
abstract interface class CanvasImageAssetResolver {
  Future<Map<String, String>> resolveSources(List<String> sourceRefs);

  Future<Map<String, Size2D>> resolveIntrinsicSizes(List<String> sourceRefs);
}
