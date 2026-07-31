// Path: lib/src/services/services_context.dart

import 'package:canvas_core/src/services/services.dart';
import 'package:canvas_core/src/services/text_measure.dart';
import 'package:canvas_core/src/services/icon_resolver.dart';
import 'package:canvas_core/src/foundation/core_types.dart' show Size2D;

class CoreServices {
  final TextMeasurer tm;
  final ImageIntrinsics? images;
  final TextMeasureCache? textMeasureCache;
  final IconResolver? icons;

  const CoreServices({
    required this.tm,
    this.images,
    this.textMeasureCache,
    this.icons,
  });
}

extension CoreServicesTextMeasureX on CoreServices {
  /// Measures the original text using native logical-unit letter spacing.
  ///
  /// Uses [textMeasureCache] when available for the current pass.
  Size2D measureText({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) {
    final cache = textMeasureCache;

    if (cache != null) {
      return cache.measure(
        measurer: tm,
        text: text,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        fontSize: fontSize,
        letterSpacing: letterSpacing,
      );
    }

    return tm.measure(
      text: text,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
    );
  }
}
