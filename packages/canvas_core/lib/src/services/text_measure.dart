// Path: lib/src/services/text_measure.dart
//
// Text measurement helpers (runtime-safe).
//
// This lives in /services because it is:
// - a caching utility for the host-provided TextMeasurer
// - used by scene geometry/layout/build passes
//
// It must NOT depend on /layout to keep dependency direction clean.

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/services/services.dart';

/// Cache for text measurements within a single layout/build/hit-test pass.
///
/// The cache is scoped to a single pass to ensure measurements remain fresh
/// and do not become stale after font changes or other updates.
class TextMeasureCache {
  final Map<
    (String text, String family, int weight, double size, double spacing),
    Size2D
  >
  _cache = {};

  Size2D measure({
    required TextMeasurer measurer,
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) {
    final key = (text, fontFamily, fontWeight, fontSize, letterSpacing);

    return _cache.putIfAbsent(
      key,
      () => measurer.measure(
        text: text,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        fontSize: fontSize,
        letterSpacing: letterSpacing,
      ),
    );
  }
}
