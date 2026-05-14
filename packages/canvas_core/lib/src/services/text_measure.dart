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
/// and don't become stale after font changes or other updates.
class TextMeasureCache {
  final Map<
    (String text, String family, int weight, double size, int spacing),
    Size2D
  >
  _cache = {};

  Size2D measureSpaced({
    required TextMeasurer measurer,
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required int letterSpacing,
  }) {
    final key = (text, fontFamily, fontWeight, fontSize, letterSpacing);
    return _cache.putIfAbsent(
      key,
      () => measurer.measureSpaced(
        text: text,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        fontSize: fontSize,
        letterSpacing: letterSpacing,
      ),
    );
  }
}

/// Shared helper: inserts `n` hair spaces between characters.
/// Pure Dart. No Flutter.
String spacedText(String text, int n) {
  if (n <= 0 || text.isEmpty) return text;
  const hair = '\u200A';
  final spacer = List.filled(n, hair).join();
  return text.split('').join(spacer);
}

extension TextMeasurerX on TextMeasurer {
  /// Always measure with hair-space expansion applied.
  /// Forces letterSpacing=0 for the platform measurer.
  Size2D measureSpaced({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required int letterSpacing,
  }) {
    return measure(
      text: spacedText(text, letterSpacing),
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontSize: fontSize,
      letterSpacing: 0,
    );
  }
}
