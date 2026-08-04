// Path: lib/src/services/services_context.dart

import 'package:canvas_core/src/foundation/core_types.dart' show Size2D;
import 'package:canvas_core/src/services/icon_resolver.dart';
import 'package:canvas_core/src/services/services.dart';

class CoreServices {
  final TextMeasurer tm;
  final ImageIntrinsics? images;
  final IconResolver? icons;

  const CoreServices({required this.tm, this.images, this.icons});
}

extension CoreServicesTextMeasureX on CoreServices {
  /// Measures the original text using native logical-unit letter spacing.
  Size2D measureText({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) {
    return tm.measure(
      text: text,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
    );
  }
}
