// Path: oss_packages/canvas_core/lib/src/foundation/core_types.dart

/// Platform-neutral primitives for geometry, color, font weight, and gradients.
/// Pure Dart (no Flutter), small and serializable.
library;

import 'dart:math' as math;

/// 32-bit ARGB color. Same layout as Flutter's [Color] under the hood:
/// 0xAARRGGBB (e.g., 0xFF112233).
typedef Color32 = int;

/// Numeric font weight (100, 200, …, 900). Common values: 400 (normal), 700 (bold).
typedef FontWeightNum = int;

/// Internal: robust numeric parsing for JSON fields.
/// Accepts `num` or numeric `String`. Returns `double` or `null` if not parseable.
double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// 2D point/vector.
class Vec2 {
  final double x;
  final double y;
  const Vec2(this.x, this.y);

  static const zero = Vec2(0, 0);

  Vec2 operator +(Vec2 o) => Vec2(x + o.x, y + o.y);
  Vec2 operator -(Vec2 o) => Vec2(x - o.x, y - o.y);
  Vec2 operator *(double s) => Vec2(x * s, y * s);
  Vec2 operator /(double s) => Vec2(x / s, y / s);

  double get length => math.sqrt(x * x + y * y);
  Vec2 get normalized => length == 0 ? this : this / length;

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  /// Fail-fast: requires numeric `x` and `y`.
  factory Vec2.fromJson(Map<String, dynamic> json) {
    final dx = _asDouble(json['x']);
    final dy = _asDouble(json['y']);
    if (dx == null || dy == null) {
      throw FormatException(
        'Vec2 requires numeric x/y; got x=${json['x']} (${json['x']?.runtimeType}), '
        'y=${json['y']} (${json['y']?.runtimeType})',
      );
    }
    return Vec2(dx, dy);
  }

  Vec2 copyWith({double? x, double? y}) => Vec2(x ?? this.x, y ?? this.y);

  @override
  String toString() => 'Vec2($x, $y)';

  @override
  bool operator ==(Object other) =>
      other is Vec2 && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// 2D size (width/height).
class Size2D {
  final double w;
  final double h;
  const Size2D(this.w, this.h);

  static const zero = Size2D(0, 0);

  Map<String, dynamic> toJson() => {'w': w, 'h': h};

  /// Fail-fast: requires numeric `w` and `h`.
  factory Size2D.fromJson(Map<String, dynamic> json) {
    final dw = _asDouble(json['w']);
    final dh = _asDouble(json['h']);
    if (dw == null || dh == null) {
      throw FormatException(
        'Size2D requires numeric w/h; got w=${json['w']} (${json['w']?.runtimeType}), '
        'h=${json['h']} (${json['h']?.runtimeType})',
      );
    }
    return Size2D(dw, dh);
  }

  Size2D copyWith({double? w, double? h}) => Size2D(w ?? this.w, h ?? this.h);

  @override
  String toString() => 'Size2D($w, $h)';

  @override
  bool operator ==(Object other) =>
      other is Size2D && other.w == w && other.h == h;

  @override
  int get hashCode => Object.hash(w, h);
}

/// Linear gradient parameters in core space.
/// - [angle] in degrees (0° = +X axis; same as your current usage)
/// - [width] 0..50 (matches your editor semantics)
class LinearGradientSpec {
  final Color32 color1;
  final Color32 color2;
  final double angle; // degrees
  final double width; // 0..50

  const LinearGradientSpec({
    required this.color1,
    required this.color2,
    this.angle = 0,
    this.width = 0,
  });

  static const transparent = LinearGradientSpec(
    color1: 0x00000000,
    color2: 0x00000000,
    angle: 0,
    width: 0,
  );

  LinearGradientSpec copyWith({
    Color32? color1,
    Color32? color2,
    double? angle,
    double? width,
  }) => LinearGradientSpec(
    color1: color1 ?? this.color1,
    color2: color2 ?? this.color2,
    angle: angle ?? this.angle,
    width: width ?? this.width,
  );

  Map<String, dynamic> toJson() => {
    'color1': color1,
    'color2': color2,
    'angle': angle,
    'width': width,
  };

  factory LinearGradientSpec.fromJson(Map<String, dynamic> json) =>
      LinearGradientSpec(
        color1: (json['color1'] as num?)?.toInt() ?? 0x00000000,
        color2: (json['color2'] as num?)?.toInt() ?? 0x00000000,
        angle: (json['angle'] as num?)?.toDouble() ?? 0,
        width: (json['width'] as num?)?.toDouble() ?? 0,
      );

  @override
  String toString() =>
      'LinearGradientSpec(c1=0x${color1.toRadixString(16)}, c2=0x${color2.toRadixString(16)}, angle=$angle, width=$width)';

  @override
  bool operator ==(Object other) =>
      other is LinearGradientSpec &&
      other.color1 == color1 &&
      other.color2 == color2 &&
      other.angle == angle &&
      other.width == width;

  @override
  int get hashCode => Object.hash(color1, color2, angle, width);
}
