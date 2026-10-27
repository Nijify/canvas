import 'dart:math' as math;
import 'dart:typed_data';

import 'package:canvas_core/src/foundation/core_types.dart' show Vec2;

/// Immutable local-to-parent affine mapping, in SVG order [a, b, c, d, e, f].
/// `A * B` applies B first, then A. Hierarchy composition is parent * local.
final class Affine2D {
  const Affine2D.identity()
    : a = 1, b = 0, c = 0, d = 1, e = 0, f = 0;

  factory Affine2D(double a, double b, double c, double d, double e, double f) {
    if (![a, b, c, d, e, f].every((value) => value.isFinite)) {
      throw ArgumentError('Affine coefficients must be finite.');
    }
    return Affine2D._(a, b, c, d, e, f);
  }

  const Affine2D._(this.a, this.b, this.c, this.d, this.e, this.f);

  factory Affine2D.translation(double x, double y) => Affine2D(1, 0, 0, 1, x, y);

  factory Affine2D.rotation(double radians) {
    if (!radians.isFinite) throw ArgumentError.value(radians, 'radians');
    final cos = math.cos(radians), sin = math.sin(radians);
    return Affine2D(cos, sin, -sin, cos, 0, 0);
  }

  factory Affine2D.scale(double x, [double? y]) => Affine2D(x, 0, 0, y ?? x, 0, 0);

  /// Linear shear factors, not angles: x' = x + xFactor*y, y' = y + yFactor*x.
  factory Affine2D.shear(double xFactor, double yFactor) =>
      Affine2D(1, yFactor, xFactor, 1, 0, 0);

  factory Affine2D.fromJson(Object? json) {
    if (json is! List || json.length != 6 ||
        json.any((value) => value is! num || !value.isFinite)) {
      throw const FormatException('xf must contain exactly six finite numbers.');
    }
    final v = json.cast<num>().map((value) => value.toDouble()).toList();
    if (v.any((value) => !value.isFinite)) {
      throw const FormatException('xf coefficients must be finite doubles.');
    }
    return Affine2D(v[0], v[1], v[2], v[3], v[4], v[5]);
  }

  final double a, b, c, d, e, f;

  bool get isIdentity => a == 1 && b == 0 && c == 0 && d == 1 && e == 0 && f == 0;

  List<double> toJson() => [a, b, c, d, e, f];

  Affine2D operator *(Affine2D other) => Affine2D(
    a * other.a + c * other.b,
    b * other.a + d * other.b,
    a * other.c + c * other.d,
    b * other.c + d * other.d,
    a * other.e + c * other.f + e,
    b * other.e + d * other.f + f,
  );

  Vec2 transformPoint(Vec2 point) => _finitePoint(
    a * point.x + c * point.y + e,
    b * point.x + d * point.y + f,
  );

  Vec2 transformVector(Vec2 vector) => _finitePoint(
    a * vector.x + c * vector.y,
    b * vector.x + d * vector.y,
  );

  /// The determinant may overflow/underflow double range; inversion uses a
  /// normalized linear part instead of comparing this value to an epsilon.
  double get determinant {
    final scale = _linearMagnitude;
    if (scale == 0) return 0;
    final normalized = (a / scale) * (d / scale) - (b / scale) * (c / scale);
    return normalized == 0 ? 0 : normalized * scale * scale;
  }

  double get _linearMagnitude => math.max(
    math.max(a.abs(), b.abs()), math.max(c.abs(), d.abs()),
  );

  /// Returns null for singular, poorly conditioned, or unrepresentable inverses.
  /// Conditioning uses the 2x2 linear part; translation does not influence it.
  /// Uniformly tiny/large well-conditioned matrices are not rejected by size.
  Affine2D? tryInverse({double minReciprocalCondition = 1e-12}) {
    if (!minReciprocalCondition.isFinite || minReciprocalCondition < 0 ||
        minReciprocalCondition > 1) {
      throw ArgumentError.value(minReciprocalCondition, 'minReciprocalCondition');
    }
    final scale = _linearMagnitude;
    if (scale == 0) return null;
    final an = a / scale, bn = b / scale, cn = c / scale, dn = d / scale;
    final det = an * dn - bn * cn;
    final norm = math.max(an.abs() + bn.abs(), cn.abs() + dn.abs());
    final adjNorm = math.max(dn.abs() + bn.abs(), cn.abs() + an.abs());
    if (det == 0 || det.abs() / (norm * adjNorm) < minReciprocalCondition) {
      return null;
    }
    final ia = (dn / det) / scale, ib = (-bn / det) / scale;
    final ic = (-cn / det) / scale, id = (an / det) / scale;
    try {
      return Affine2D(ia, ib, ic, id, -(ia * e + ic * f), -(ib * e + id * f));
    } on ArgumentError {
      return null;
    }
  }

  /// Fresh column-major framework data, derived only at a rendering boundary.
  Float64List toColumnMajor4x4() => Float64List.fromList([
    a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, e, f, 0, 1,
  ]);

  static Vec2 _finitePoint(double x, double y) {
    if (!x.isFinite || !y.isFinite) {
      throw ArgumentError('Affine operation produced nonfinite coordinates.');
    }
    return Vec2(x, y);
  }

  @override
  bool operator ==(Object other) => identical(this, other) ||
      other is Affine2D && a == other.a && b == other.b && c == other.c &&
      d == other.d && e == other.e && f == other.f;

  @override
  int get hashCode => Object.hash(a, b, c, d, e, f);

  @override
  String toString() => 'Affine2D($a, $b, $c, $d, $e, $f)';
}
