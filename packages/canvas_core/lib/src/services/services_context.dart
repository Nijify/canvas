// Path: lib/src/services/services_context.dart

import 'package:canvas_core/src/services/icon_resolver.dart';
import 'package:canvas_core/src/services/services.dart';

class CoreServices {
  const CoreServices({required this.textMeasurer, this.images, this.icons});

  final TextMeasurer textMeasurer;
  final ImageIntrinsics? images;
  final IconResolver? icons;
}
