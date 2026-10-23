import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;

/// Absolute, normalized geometry operations. Paint belongs to the authored node.
enum PathVerb { moveTo, lineTo, cubicTo, close }

final class PathCmd {
  final PathVerb verb;
  final Vec2 p;
  final Vec2? c1;
  final Vec2? c2;
  const PathCmd._(this.verb, this.p, [this.c1, this.c2]);

  factory PathCmd.moveTo(Vec2 p) => PathCmd._(PathVerb.moveTo, p);
  factory PathCmd.lineTo(Vec2 p) => PathCmd._(PathVerb.lineTo, p);
  factory PathCmd.cubicTo(Vec2 c1, Vec2 c2, Vec2 p) =>
      PathCmd._(PathVerb.cubicTo, p, c1, c2);
  factory PathCmd.close() => const PathCmd._(PathVerb.close, Vec2.zero);
}

/// Validated, immutable geometry shared by paths and prepared icon resources.
/// Each contour starts with moveTo. A close ends that contour; SVG input that
/// continues drawing after close is normalized by the SVG codec.
final class PathIR {
  final List<PathCmd> cmds;

  PathIR(List<PathCmd> commands) : cmds = List.unmodifiable(commands) {
    var open = false;
    for (var i = 0; i < cmds.length; i++) {
      final command = cmds[i];
      if (command.verb == PathVerb.moveTo) {
        open = true;
      } else if (!open) {
        throw ArgumentError('commands[$i] requires a preceding moveTo.');
      }
      if (command.verb == PathVerb.close) {
        open = false;
        continue;
      }
      for (final point in [command.p, command.c1, command.c2]) {
        if (point != null && (!point.x.isFinite || !point.y.isFinite)) {
          throw ArgumentError('commands[$i] must have finite coordinates.');
        }
      }
    }
  }

  bool get hasSegments => cmds.any(
    (command) =>
        command.verb == PathVerb.lineTo || command.verb == PathVerb.cubicTo,
  );

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

    for (final command in cmds) {
      if (command.verb == PathVerb.close) continue;
      acc(command.p);
      if (command.c1 != null) acc(command.c1!);
      if (command.c2 != null) acc(command.c2!);
    }
    return Rect2D.fromLTRB(minX, minY, maxX, maxY);
  }
}
