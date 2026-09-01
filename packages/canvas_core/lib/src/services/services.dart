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

/// Resolves logical canvas image source references for the current host.
///
/// Each input is an opaque logical `sourceRef` stored by the canvas document.
///
/// Result maps are keyed by the exact `sourceRef` values supplied to the
/// corresponding method. Returned maps may be partial; a missing key means
/// that source or intrinsic metadata could not be resolved.
///
/// [resolveSources] returns source references that the current rendering host
/// can load. These outputs are runtime values, not persistent resource
/// identities. They may be temporary or rotating values such as signed URLs or
/// blob URLs.
///
/// A renderable source is not necessarily a URL. Depending on the host it may
/// be an `https:`, `data:`, `blob:`, `asset:`, `file:`, or another supported
/// source reference.
///
/// [resolveIntrinsicSizes] returns stable layout-affecting metadata associated
/// with the logical image content.
abstract interface class CanvasImageAssetResolver {
  Future<Map<String, String>> resolveSources(List<String> sourceRefs);

  Future<Map<String, Size2D>> resolveIntrinsicSizes(List<String> sourceRefs);
}
