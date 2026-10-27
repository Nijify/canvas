import 'dart:math' as math;
import 'package:canvas_core/src/foundation/core_types.dart' show Vec2;
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;
import 'package:canvas_core/src/foundation/math/affine2d.dart' show Affine2D;

/// Ordered perimeter corners (top-left, top-right, bottom-right, bottom-left).
List<Vec2> transformedRectCorners(Rect2D rect, Affine2D matrix) => List.unmodifiable([
  matrix.transformPoint(Vec2(rect.left, rect.top)),
  matrix.transformPoint(Vec2(rect.right, rect.top)),
  matrix.transformPoint(Vec2(rect.right, rect.bottom)),
  matrix.transformPoint(Vec2(rect.left, rect.bottom)),
]);

Rect2D aabbOfTransformedRect(Rect2D rect, Affine2D matrix) {
  final points = transformedRectCorners(rect, matrix);
  final left = points.map((p) => p.x).reduce(math.min);
  final top = points.map((p) => p.y).reduce(math.min);
  final right = points.map((p) => p.x).reduce(math.max);
  final bottom = points.map((p) => p.y).reduce(math.max);
  if (!(right - left).isFinite || !(bottom - top).isFinite) {
    throw ArgumentError('Transformed bounds exceed finite geometry range.');
  }
  return Rect2D.fromLTRB(left, top, right, bottom);
}
