// Path: lib/src/path/path_hit_test.dart

import 'package:canvas_core/src/foundation/core_types.dart' show Vec2;
import 'package:canvas_core/src/foundation/style/style_types.dart'
    show FillRule;
import 'package:canvas_core/src/path/path_ir.dart' show PathIR, PathVerb;

class _Contour {
  final List<Vec2> pts;
  final bool closed;
  const _Contour(this.pts, this.closed);
}

/// True when [p] is inside the fill area of the path, using the path's
/// fill rule.
///
/// This is geometry-based and intentionally does NOT depend on whether fill is
/// currently rendered.
///
/// Important: for fill hit semantics, open subpaths are treated as implicitly
/// closed for containment testing.
bool pathContainsClosedArea(PathIR ir, Vec2 p, {int curveSteps = 16}) {
  final contours = _flattenContours(ir, curveSteps: curveSteps);
  if (contours.isEmpty) return false;

  return switch (ir.style.fillRule) {
    FillRule.evenOdd => _insideEvenOdd(contours, p, closeImplicitly: true),
    FillRule.nonZero => _insideNonZero(contours, p, closeImplicitly: true),
  };
}

/// True when [p] is within [radiusLocal] of any segment of the path.
/// Use this for editor hit slop / outline proximity picking.
bool pathHitsOutline(
  PathIR ir,
  Vec2 p, {
  required double radiusLocal,
  int curveSteps = 16,
}) {
  if (radiusLocal <= 0) return false;

  final r2 = radiusLocal * radiusLocal;
  final contours = _flattenContours(ir, curveSteps: curveSteps);
  if (contours.isEmpty) return false;

  for (final c in contours) {
    final pts = c.pts;
    if (pts.length < 2) continue;

    for (var i = 0; i < pts.length - 1; i++) {
      if (_dist2PointToSegment(p, pts[i], pts[i + 1]) <= r2) return true;
    }

    if (c.closed) {
      if (_dist2PointToSegment(p, pts.last, pts.first) <= r2) return true;
    }
  }

  return false;
}

List<_Contour> _flattenContours(PathIR ir, {int curveSteps = 16}) {
  final out = <_Contour>[];

  List<Vec2> current = <Vec2>[];
  Vec2? start;
  Vec2? prev;
  bool closed = false;

  void flush() {
    if (current.length >= 2) {
      out.add(_Contour(List<Vec2>.from(current), closed));
    }
    current = <Vec2>[];
    start = null;
    prev = null;
    closed = false;
  }

  for (final cmd in ir.cmds) {
    switch (cmd.verb) {
      case PathVerb.moveTo:
        flush();
        start = cmd.p;
        prev = cmd.p;
        current.add(cmd.p);
        break;

      case PathVerb.lineTo:
        prev = cmd.p;
        current.add(cmd.p);
        break;

      case PathVerb.quadTo:
        final p0 = prev;
        if (p0 == null) break;
        final c1 = cmd.c1!;
        final p1 = cmd.p;
        for (var i = 1; i <= curveSteps; i++) {
          final t = i / curveSteps;
          current.add(_quad(p0, c1, p1, t));
        }
        prev = p1;
        break;

      case PathVerb.cubicTo:
        final p0 = prev;
        if (p0 == null) break;
        final c1 = cmd.c1!;
        final c2 = cmd.c2!;
        final p1 = cmd.p;
        for (var i = 1; i <= curveSteps; i++) {
          final t = i / curveSteps;
          current.add(_cubic(p0, c1, c2, p1, t));
        }
        prev = p1;
        break;

      case PathVerb.close:
        closed = true;
        if (start == null) {
          closed = false;
        }
        flush();
        break;
    }
  }

  flush();
  return out;
}

bool _insideEvenOdd(List<_Contour> cs, Vec2 p, {bool closeImplicitly = false}) {
  var inside = false;
  for (final c in cs) {
    inside = inside ^ _rayCrossingsOdd(c, p, closeImplicitly: closeImplicitly);
  }
  return inside;
}

bool _rayCrossingsOdd(_Contour c, Vec2 p, {bool closeImplicitly = false}) {
  final pts = c.pts;
  if (pts.length < 2) return false;

  var odd = false;

  void testSeg(Vec2 a, Vec2 b) {
    final ay = a.y, by = b.y;
    final ax = a.x, bx = b.x;

    final cond = ((ay > p.y) != (by > p.y));
    if (!cond) return;

    final xInt = ax + (bx - ax) * ((p.y - ay) / (by - ay));
    if (xInt > p.x) odd = !odd;
  }

  for (var i = 0; i < pts.length - 1; i++) {
    testSeg(pts[i], pts[i + 1]);
  }
  if (c.closed || closeImplicitly) {
    testSeg(pts.last, pts.first);
  }

  return odd;
}

bool _insideNonZero(List<_Contour> cs, Vec2 p, {bool closeImplicitly = false}) {
  var wn = 0;
  for (final c in cs) {
    wn += _windingNumber(c, p, closeImplicitly: closeImplicitly);
  }
  return wn != 0;
}

int _windingNumber(_Contour c, Vec2 p, {bool closeImplicitly = false}) {
  final pts = c.pts;
  if (pts.length < 2) return 0;

  int wn = 0;

  void testSeg(Vec2 a, Vec2 b) {
    if (a.y <= p.y) {
      if (b.y > p.y && _isLeft(a, b, p) > 0) wn++;
    } else {
      if (b.y <= p.y && _isLeft(a, b, p) < 0) wn--;
    }
  }

  for (var i = 0; i < pts.length - 1; i++) {
    testSeg(pts[i], pts[i + 1]);
  }
  if (c.closed || closeImplicitly) {
    testSeg(pts.last, pts.first);
  }

  return wn;
}

double _isLeft(Vec2 a, Vec2 b, Vec2 p) {
  return (b.x - a.x) * (p.y - a.y) - (p.x - a.x) * (b.y - a.y);
}

double _dist2PointToSegment(Vec2 p, Vec2 a, Vec2 b) {
  final abx = b.x - a.x;
  final aby = b.y - a.y;
  final apx = p.x - a.x;
  final apy = p.y - a.y;
  final abLen2 = abx * abx + aby * aby;

  if (abLen2 <= 1e-12) {
    final dx = p.x - a.x;
    final dy = p.y - a.y;
    return dx * dx + dy * dy;
  }

  var t = (apx * abx + apy * aby) / abLen2;
  t = t.clamp(0.0, 1.0);

  final cx = a.x + abx * t;
  final cy = a.y + aby * t;

  final dx = p.x - cx;
  final dy = p.y - cy;
  return dx * dx + dy * dy;
}

Vec2 _quad(Vec2 p0, Vec2 c1, Vec2 p1, double t) {
  final u = 1.0 - t;
  final x = u * u * p0.x + 2 * u * t * c1.x + t * t * p1.x;
  final y = u * u * p0.y + 2 * u * t * c1.y + t * t * p1.y;
  return Vec2(x, y);
}

Vec2 _cubic(Vec2 p0, Vec2 c1, Vec2 c2, Vec2 p1, double t) {
  final u = 1.0 - t;
  final tt = t * t;
  final uu = u * u;
  final uuu = uu * u;
  final ttt = tt * t;

  final x = uuu * p0.x + 3 * uu * t * c1.x + 3 * u * tt * c2.x + ttt * p1.x;
  final y = uuu * p0.y + 3 * uu * t * c1.y + 3 * u * tt * c2.y + ttt * p1.y;

  return Vec2(x, y);
}
