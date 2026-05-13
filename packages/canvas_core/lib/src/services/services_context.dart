// Path: oss_packages/canvas_core/lib/src/services/services_context.dart

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
  /// Measures text after applying your "hair-space" letterSpacing expansion.
  /// Uses [textMeasureCache] when available (per-pass), otherwise calls measurer directly.
  Size2D measureSpacedText({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required int letterSpacing,
  }) {
    final cache = textMeasureCache;
    if (cache != null) {
      return cache.measureSpaced(
        measurer: tm,
        text: text,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        fontSize: fontSize,
        letterSpacing: letterSpacing,
      );
    }

    // Uses TextMeasurerX.measureSpaced from text_measure.dart (already imported here)
    return tm.measureSpaced(
      text: text,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
    );
  }
}
