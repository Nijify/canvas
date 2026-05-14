// Path: lib/src/foundation/geometry/geometry_ext.dart

import 'dart:math' as math;
import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;

extension Rect2DX on Rect2D {
  Vec2 get center => Vec2((left + right) * 0.5, (top + bottom) * 0.5);

  Rect2D inflate(double r) =>
      Rect2D.fromLTRB(left - r, top - r, right + r, bottom + r);

  Rect2D translate(Vec2 d) =>
      Rect2D.fromLTRB(left + d.x, top + d.y, right + d.x, bottom + d.y);

  bool intersects(Rect2D o) =>
      left <= o.right && right >= o.left && top <= o.bottom && bottom >= o.top;

  static Rect2D union(Rect2D a, Rect2D b) => Rect2D.fromLTRB(
    math.min(a.left, b.left),
    math.min(a.top, b.top),
    math.max(a.right, b.right),
    math.max(a.bottom, b.bottom),
  );
}
