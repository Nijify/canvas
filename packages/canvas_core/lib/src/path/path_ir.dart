// Path: oss_packages/canvas_core/lib/src/path/path_ir.dart

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;
import 'package:canvas_core/src/foundation/style/style_types.dart'
    show FillRule, StrokeCap, StrokeJoin;

enum PathVerb { moveTo, lineTo, quadTo, cubicTo, close }

class PathCmd {
  final PathVerb verb;
  final Vec2 p; // for moveTo/lineTo/close (p ignored for close)
  final Vec2? c1; // quad: c1 is control; cubic: c1/c2
  final Vec2? c2;
  const PathCmd._(this.verb, this.p, [this.c1, this.c2]);

  factory PathCmd.moveTo(Vec2 p) => PathCmd._(PathVerb.moveTo, p);
  factory PathCmd.lineTo(Vec2 p) => PathCmd._(PathVerb.lineTo, p);
  factory PathCmd.quadTo(Vec2 c, Vec2 p) => PathCmd._(PathVerb.quadTo, p, c);
  factory PathCmd.cubicTo(Vec2 c1, Vec2 c2, Vec2 p) =>
      PathCmd._(PathVerb.cubicTo, p, c1, c2);
  factory PathCmd.close() => const PathCmd._(PathVerb.close, Vec2.zero);
}

class PathStyle {
  final Color32? fill; // null => no fill
  final FillRule fillRule;
  final Color32? stroke; // null => no stroke
  final double strokeWidth;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  final double miterLimit;
  final List<double>? dash; // [on, off, on, off, ...]

  const PathStyle({
    this.fill,
    this.fillRule = FillRule.nonZero,
    this.stroke,
    this.strokeWidth = 1.0,
    this.strokeCap = StrokeCap.butt,
    this.strokeJoin = StrokeJoin.miter,
    this.miterLimit = 4.0,
    this.dash,
  });

  PathStyle copyWith({
    Color32? fill,
    FillRule? fillRule,
    Color32? stroke,
    double? strokeWidth,
    StrokeCap? strokeCap,
    StrokeJoin? strokeJoin,
    double? miterLimit,
    List<double>? dash,
  }) => PathStyle(
    fill: fill ?? this.fill,
    fillRule: fillRule ?? this.fillRule,
    stroke: stroke ?? this.stroke,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    strokeCap: strokeCap ?? this.strokeCap,
    strokeJoin: strokeJoin ?? this.strokeJoin,
    miterLimit: miterLimit ?? this.miterLimit,
    dash: dash ?? this.dash,
  );
}

/// Canonical compiled representation used everywhere internally.
class PathIR {
  final List<PathCmd> cmds;
  final PathStyle style;

  const PathIR(this.cmds, this.style);

  /// Cheap local AABB (optionally includes stroke expansion)
  Rect2D localBounds({bool includeStroke = true}) {
    if (cmds.isEmpty) return const Rect2D(0, 0, 0, 0);
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    void acc(Vec2 v) {
      if (v.x < minX) minX = v.x;
      if (v.x > maxX) maxX = v.x;
      if (v.y < minY) minY = v.y;
      if (v.y > maxY) maxY = v.y;
    }

    for (final c in cmds) {
      switch (c.verb) {
        case PathVerb.moveTo:
        case PathVerb.lineTo:
          acc(c.p);
          break;
        case PathVerb.quadTo:
          acc(c.p);
          acc(c.c1!);
          break;
        case PathVerb.cubicTo:
          acc(c.p);
          acc(c.c1!);
          acc(c.c2!);
          break;
        case PathVerb.close:
          break;
      }
    }
    if (includeStroke && style.stroke != null && style.strokeWidth > 0) {
      final r = style.strokeWidth / 2.0;
      return Rect2D.fromLTRB(minX - r, minY - r, maxX + r, maxY + r);
    }
    return Rect2D.fromLTRB(minX, minY, maxX, maxY);
  }
}
