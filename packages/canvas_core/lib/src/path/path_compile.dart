// Path: lib/src/path/path_compile.dart

import 'dart:math' as math;

import 'package:canvas_core/src/path/path_ir.dart';
import 'package:canvas_core/src/path/path_source.dart';
import 'package:canvas_core/src/foundation/core_types.dart';

class PathCompiler {
  const PathCompiler();

  PathIR fromSource(PathSource src) => switch (src) {
    CommandPathSource(:final commands) => PathIR(commands),
    PolylineSource(:final points) => _polyline(points),
    RectSource(:final w, :final h) => _rect(w, h),
    RoundRectSource(:final w, :final h, :final rx, :final ry) => _roundRect(
      w,
      h,
      rx,
      ry,
    ),
    PillSource(:final w, :final h) => _roundRect(w, h, h / 2, h / 2),
    UnderlineSource(:final w, :final thickness) => _rect(w, thickness),
    EllipseSource(:final rx, :final ry) => _ellipse(rx, ry),
    CircleSource(:final r) => _ellipse(r, r),
    RegularPolygonSource(:final sides, :final r, :final rotation) =>
      _regularPolygon(sides, r, rotation),
    StarSource(:final points, :final rOuter, :final rInner, :final rotation) =>
      _star(points, rOuter, rInner, rotation),
  };

  PathIR _regularPolygon(int sides, double r, double rotationDeg) {
    assert(sides >= 3);
    final cmds = <PathCmd>[];
    final cx = 0.0, cy = 0.0;
    final rot = rotationDeg * math.pi / 180.0;
    for (var i = 0; i < sides; i++) {
      final a = rot + i * 2 * math.pi / sides;
      final x = cx + r * math.cos(a), y = cy + r * math.sin(a);
      cmds.add(
        i == 0 ? PathCmd.moveTo(Vec2(x, y)) : PathCmd.lineTo(Vec2(x, y)),
      );
    }
    cmds.add(PathCmd.close());
    return PathIR(cmds);
  }

  PathIR _star(int points, double ro, double ri, double rotationDeg) {
    assert(points >= 3 && ri >= 0 && ri <= ro);
    final cmds = <PathCmd>[];
    final cx = 0.0, cy = 0.0;
    final rot = rotationDeg * math.pi / 180.0;
    final total = points * 2;
    for (var i = 0; i < total; i++) {
      final isOuter = i.isEven;
      final r = isOuter ? ro : ri;
      final a = rot + i * math.pi / points;
      final x = cx + r * math.cos(a), y = cy + r * math.sin(a);
      cmds.add(
        i == 0 ? PathCmd.moveTo(Vec2(x, y)) : PathCmd.lineTo(Vec2(x, y)),
      );
    }
    cmds.add(PathCmd.close());
    return PathIR(cmds);
  }

  PathIR _polyline(List<Vec2?> pts) {
    final cmds = <PathCmd>[];
    Vec2? current;
    for (final p in pts) {
      if (p == null) {
        // contour break: lift pen
        current = null;
        continue;
      }
      if (current == null) {
        cmds.add(PathCmd.moveTo(p));
      } else {
        cmds.add(PathCmd.lineTo(p));
      }
      current = p;
    }
    return PathIR(cmds);
  }

  PathIR _rect(double w, double h) {
    final hw = w / 2.0;
    final hh = h / 2.0;

    final cmds = <PathCmd>[
      PathCmd.moveTo(Vec2(-hw, -hh)),
      PathCmd.lineTo(Vec2(hw, -hh)),
      PathCmd.lineTo(Vec2(hw, hh)),
      PathCmd.lineTo(Vec2(-hw, hh)),
      PathCmd.close(),
    ];
    return PathIR(cmds);
  }

  PathIR _roundRect(double w, double h, double rx, double ry) {
    // Clamp radii defensively
    rx = rx.clamp(0.0, w / 2.0);
    ry = ry.clamp(0.0, h / 2.0);

    const k = 0.5522847498307936; // circle magic constant
    final kx = rx * k, ky = ry * k;

    final l = -w / 2.0;
    final r = w / 2.0;
    final t = -h / 2.0;
    final b = h / 2.0;

    final cmds = <PathCmd>[
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
    ];

    return PathIR(cmds);
  }

  PathIR _ellipse(double rx, double ry) {
    const k = 0.5522847498307936;

    final cmds = <PathCmd>[
      PathCmd.moveTo(Vec2(rx, 0)),
      PathCmd.cubicTo(Vec2(rx, ry * k), Vec2(rx * k, ry), Vec2(0, ry)),
      PathCmd.cubicTo(Vec2(-rx * k, ry), Vec2(-rx, ry * k), Vec2(-rx, 0)),
      PathCmd.cubicTo(Vec2(-rx, -ry * k), Vec2(-rx * k, -ry), Vec2(0, -ry)),
      PathCmd.cubicTo(Vec2(rx * k, -ry), Vec2(rx, -ry * k), Vec2(rx, 0)),
      PathCmd.close(),
    ];
    return PathIR(cmds);
  }
}
