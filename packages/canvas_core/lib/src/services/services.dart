// Path: oss_packages/canvas_core/lib/src/services/services.dart

import 'package:canvas_core/src/foundation/ids.dart';
import 'package:canvas_core/src/foundation/core_types.dart';

abstract class TextMeasurer {
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight, // 100..900
    required double fontSize,
    required int letterSpacing,
  });
}

abstract class ImageIntrinsics {
  Size2D? intrinsicSize(ElementId id);

  /// NEW: fire when an image’s intrinsic size becomes available or changes.
  /// The editor/runtime should listen and rebuild ops for that id.
  Stream<ElementId> get onIntrinsicUpdated;
  // (or: void addListener(ElementId id, VoidCallback cb); removeListener(...);)
}
