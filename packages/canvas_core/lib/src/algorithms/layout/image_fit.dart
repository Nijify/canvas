// Path: lib/src/algorithms/layout/image_fit.dart

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;
import 'package:canvas_core/src/runtime/model/node_model.dart';

({Rect2D src, Rect2D dst}) imageSrcDst({
  required Size2D intrinsic,
  required Size2D layout,
  required ImageFit fit,
  required Vec2 align, // 0..1
}) {
  // guard
  if (intrinsic.w <= 0 || intrinsic.h <= 0 || layout.w <= 0 || layout.h <= 0) {
    final zero = Rect2D.fromLTWH(0, 0, 0, 0);
    return (src: zero, dst: zero);
  }

  final iw = intrinsic.w, ih = intrinsic.h;
  final lw = layout.w, lh = layout.h;
  final iAspect = iw / ih;
  final lAspect = lw / lh;

  // Default: full source, full destination (TL-anchored for now)
  var src = Rect2D.fromLTWH(0, 0, iw, ih);
  var dst = Rect2D.fromLTWH(0, 0, lw, lh);

  switch (fit) {
    case ImageFit.fill:
      // stretch: src full, dst full (non-uniform scale)
      // dst stays full layout box
      break;

    case ImageFit.cover:
      // crop source so its aspect == layout aspect, then map to full dst
      if (iAspect > lAspect) {
        // source wider than layout → crop width
        final neededW = ih * lAspect;
        final excessW = iw - neededW;
        final left = excessW * align.x; // 0..excess, aligned
        src = Rect2D.fromLTWH(left, 0, neededW, ih);
      } else {
        // source taller → crop height
        final neededH = iw / lAspect;
        final excessH = ih - neededH;
        final top = excessH * align.y;
        src = Rect2D.fromLTWH(0, top, iw, neededH);
      }
      // dst stays full layout box
      break;

    case ImageFit.contain:
      // no crop; letterbox inside layout. Keep src full intrinsic
      // and reduce dst to the inscribed rect, aligned within the layout box.
      if (iAspect > lAspect) {
        // limit by width
        final h = lw / iAspect;
        final top = (lh - h) * align.y;
        dst = Rect2D.fromLTWH(0, top, lw, h);
      } else {
        // limit by height
        final w = lh * iAspect;
        final left = (lw - w) * align.x;
        dst = Rect2D.fromLTWH(left, 0, w, lh);
      }
      break;
  }

  // ✅ Center-origin convention:
  // Local-space should be centered at (0,0), so shift destination rect by (-lw/2, -lh/2)
  // while preserving any letterbox/crop offsets computed above.
  dst = Rect2D.fromLTWH(
    dst.left - lw / 2.0,
    dst.top - lh / 2.0,
    dst.width,
    dst.height,
  );

  return (src: src, dst: dst);
}
