// Path: lib/src/path/path_ir.dart

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;

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

/// Immutable compiled geometry. Paint belongs to the authored node.
class PathIR {
  /// An immutable snapshot of the commands supplied to the constructor.
  final List<PathCmd> cmds;
  PathIR(List<PathCmd> cmds) : cmds = List<PathCmd>.unmodifiable(cmds);

  /// Conservative source-space AABB from endpoints and curve controls.
  Rect2D localBounds() {
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
    return Rect2D.fromLTRB(minX, minY, maxX, maxY);
  }
}
