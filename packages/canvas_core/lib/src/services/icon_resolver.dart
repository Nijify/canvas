// Path: lib/src/services/icon_resolver.dart

import 'package:canvas_core/src/foundation/core_types.dart' show FontWeightNum;
import 'package:canvas_core/src/runtime/model/node_model.dart' show PathData;

/// Sync resolver: the core pipeline (layout + paint op build) is synchronous.
/// Any async download/fetch happens outside core (app/editor layer),
/// then you provide a resolver that can answer synchronously.
abstract interface class IconResolver {
  ResolvedIcon? resolve(String iconRef);
}

sealed class ResolvedIcon {
  const ResolvedIcon();
}

/// Font-backed icon (glyph in a font family).
final class ResolvedIconText extends ResolvedIcon {
  const ResolvedIconText({
    required this.glyph,
    required this.fontFamily,
    this.fontWeight = 900,
  });

  final String glyph;
  final String fontFamily;
  final FontWeightNum fontWeight;
}

/// Vector-backed icon (future-proof). Contract for now:
/// the returned PathData should be normalized to your icon origin convention
/// (ideally centered around (0,0) like Text baseline-center behavior).
final class ResolvedIconPath extends ResolvedIcon {
  const ResolvedIconPath(this.path);
  final PathData path;
}
