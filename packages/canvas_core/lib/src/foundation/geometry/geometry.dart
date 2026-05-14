// Path: lib/src/foundation/geometry/geometry.dart

import 'package:canvas_core/src/foundation/core_types.dart';

class Rect2D {
  final double left, top, right, bottom;
  const Rect2D(this.left, this.top, this.right, this.bottom);

  factory Rect2D.fromLTWH(double l, double t, double w, double h) =>
      Rect2D(l, t, l + w, t + h);

  factory Rect2D.fromLTRB(double l, double t, double r, double b) =>
      Rect2D(l, t, r, b);

  double get width => right - left;
  double get height => bottom - top;

  bool contains(Vec2 p) =>
      p.x >= left && p.x <= right && p.y >= top && p.y <= bottom;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rect2D &&
          left == other.left &&
          top == other.top &&
          right == other.right &&
          bottom == other.bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'Rect2D($left, $top, $right, $bottom)';
}
