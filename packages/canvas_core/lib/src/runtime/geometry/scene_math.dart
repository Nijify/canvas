// Path: lib/src/runtime/geometry/scene_math.dart

import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;

Rect2D aabbOfTransformedRect(Rect2D r, vm.Matrix4 m) {
  // Transform 4 corners; compute min/max in world space.
  final p1 = _tx(m, r.left, r.top);
  final p2 = _tx(m, r.right, r.top);
  final p3 = _tx(m, r.right, r.bottom);
  final p4 = _tx(m, r.left, r.bottom);

  final minX = math.min(math.min(p1.x, p2.x), math.min(p3.x, p4.x));
  final minY = math.min(math.min(p1.y, p2.y), math.min(p3.y, p4.y));
  final maxX = math.max(math.max(p1.x, p2.x), math.max(p3.x, p4.x));
  final maxY = math.max(math.max(p1.y, p2.y), math.max(p3.y, p4.y));

  return Rect2D.fromLTRB(minX, minY, maxX, maxY);
}

vm.Vector3 _tx(vm.Matrix4 m, double x, double y) {
  final v = vm.Vector3(x, y, 0);
  m.transform3(v);
  return v;
}
