import 'dart:math' as math;
import 'package:canvas_core/src/foundation/core_types.dart' show Vec2;
import 'package:canvas_core/src/path/path_ir.dart';
import 'package:canvas_core/src/path/path_source.dart';

class PathCompiler {
  const PathCompiler();

  PathIR fromSource(PathSource source) {
    requirePathSourceIntegrity(source);
    return switch (source) {
      GeneralPathSource(:final geometry) => geometry,
      RectSource() => _rect(source),
      CircleSource(:final cx, :final cy, :final r) => _ellipse(cx, cy, r, r),
      EllipseSource(:final cx, :final cy, :final rx, :final ry) => _ellipse(
        cx,
        cy,
        rx,
        ry,
      ),
      LineSource(:final x1, :final y1, :final x2, :final y2) => PathIR([
        PathCmd.moveTo(Vec2(x1, y1)),
        PathCmd.lineTo(Vec2(x2, y2)),
      ]),
      PolylineSource(:final points) => _points(points, closed: false),
      PolygonSource(:final points) => _points(points, closed: true),
    };
  }

  PathIR _points(List<Vec2> points, {required bool closed}) => PathIR([
    if (points.isNotEmpty) PathCmd.moveTo(points.first),
    for (final point in points.skip(1)) PathCmd.lineTo(point),
    if (closed && points.isNotEmpty) PathCmd.close(),
  ]);

  PathIR _rect(RectSource source) {
    if (source.width == 0 || source.height == 0) return PathIR([]);
    final l = source.x, t = source.y;
    final r = l + source.width, b = t + source.height;
    final rx = math.min(source.rx ?? source.ry ?? 0, source.width / 2);
    final ry = math.min(source.ry ?? source.rx ?? 0, source.height / 2);
    if (rx == 0 || ry == 0)
      return PathIR([
        PathCmd.moveTo(Vec2(l, t)),
        PathCmd.lineTo(Vec2(r, t)),
        PathCmd.lineTo(Vec2(r, b)),
        PathCmd.lineTo(Vec2(l, b)),
        PathCmd.close(),
      ]);
    const k = 0.5522847498307936;
    final kx = rx * k, ky = ry * k;
    return PathIR([
      PathCmd.moveTo(Vec2(l + rx, t)),
      PathCmd.lineTo(Vec2(r - rx, t)),
      PathCmd.cubicTo(
        Vec2(r - rx + kx, t),
        Vec2(r, t + ry - ky),
        Vec2(r, t + ry),
      ),
      PathCmd.lineTo(Vec2(r, b - ry)),
      PathCmd.cubicTo(
        Vec2(r, b - ry + ky),
        Vec2(r - rx + kx, b),
        Vec2(r - rx, b),
      ),
      PathCmd.lineTo(Vec2(l + rx, b)),
      PathCmd.cubicTo(
        Vec2(l + rx - kx, b),
        Vec2(l, b - ry + ky),
        Vec2(l, b - ry),
      ),
      PathCmd.lineTo(Vec2(l, t + ry)),
      PathCmd.cubicTo(
        Vec2(l, t + ry - ky),
        Vec2(l + rx - kx, t),
        Vec2(l + rx, t),
      ),
      PathCmd.close(),
    ]);
  }

  PathIR _ellipse(double cx, double cy, double rx, double ry) {
    if (rx == 0 || ry == 0) return PathIR([]);
    const k = 0.5522847498307936;
    Vec2 p(double x, double y) => Vec2(cx + x, cy + y);
    return PathIR([
      PathCmd.moveTo(p(rx, 0)),
      PathCmd.cubicTo(p(rx, ry * k), p(rx * k, ry), p(0, ry)),
      PathCmd.cubicTo(p(-rx * k, ry), p(-rx, ry * k), p(-rx, 0)),
      PathCmd.cubicTo(p(-rx, -ry * k), p(-rx * k, -ry), p(0, -ry)),
      PathCmd.cubicTo(p(rx * k, -ry), p(rx, -ry * k), p(rx, 0)),
      PathCmd.close(),
    ]);
  }
}
