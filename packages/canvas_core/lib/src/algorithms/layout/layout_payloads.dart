// Path: lib/src/algorithms/layout/layout_payloads.dart

import 'package:canvas_core/src/foundation/geometry/geometry.dart';

final class ImagePlacement {
  final Rect2D src;
  final Rect2D dst;

  const ImagePlacement({required this.src, required this.dst});
}

final class IconTextPayload {
  final String glyph;
  final String family;
  final int weight;

  const IconTextPayload({
    required this.glyph,
    required this.family,
    required this.weight,
  });
}
