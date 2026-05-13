// Path: oss_packages/canvas_core/lib/src/foundation/math/affine2d.dart

import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:canvas_core/src/foundation/core_types.dart';

/// Compose a 2D affine transform as a Matrix4 from TRS with a local-space pivot.
/// Order: T(position) · T(pivot) · Rz(rotation) · S(scale) · T(-pivot)
vm.Matrix4 matFromTRS({
  required Vec2 position,
  required double rotationRad,
  required Vec2 scale,
  Vec2? pivotPx,
}) {
  final p = pivotPx ?? Vec2.zero;
  final m = vm.Matrix4.identity();

  m.translateByDouble(position.x, position.y, 0.0, 1.0);
  m.translateByDouble(p.x, p.y, 0.0, 1.0);
  m.rotateZ(rotationRad);
  m.scaleByDouble(scale.x, scale.y, 1.0, 1.0);
  m.translateByDouble(-p.x, -p.y, 0.0, 1.0);

  return m;
}

/// Extract Canvas2D-style [a,b,c,d,e,f] from a column-major Matrix4.
/// For 2D: a=m00, b=m10, c=m01, d=m11, e=m03? No — column-major:
/// a = m[0], b = m[1], c = m[4], d = m[5], e = m[12], f = m[13]
({List<double> six}) toABCDExy(vm.Matrix4 m) {
  final s = m.storage;
  return (six: <double>[s[0], s[1], s[4], s[5], s[12], s[13]]);
}
