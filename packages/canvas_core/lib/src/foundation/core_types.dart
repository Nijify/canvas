// Path: lib/src/foundation/core_types.dart

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

/// One color sample along a gradient line.
///
/// [offset] is expressed in the normalized gradient interval `[0, 1]`. Scene
/// validation owns range and ordering checks so callers can collect all
/// diagnostics for a document at once.
final class GradientStop {
  const GradientStop({required this.offset, required this.color});

  final double offset;
  final Color32 color;

  GradientStop copyWith({double? offset, Color32? color}) => GradientStop(
    offset: offset ?? this.offset,
    color: color ?? this.color,
  );

  Map<String, dynamic> toJson() => {'offset': offset, 'color': color};

  factory GradientStop.fromJson(Map<String, dynamic> json) {
    final offset = json['offset'];
    final color = json['color'];

    if (offset is! num || color is! int) {
      throw FormatException(
        'GradientStop requires numeric offset and integer color; '
        'got offset=$offset (${offset.runtimeType}), '
        'color=$color (${color.runtimeType})',
      );
    }

    return GradientStop(offset: offset.toDouble(), color: color);
  }

  @override
  String toString() =>
      'GradientStop(offset=$offset, color=0x${color.toRadixString(16)})';

  @override
  bool operator ==(Object other) =>
      other is GradientStop &&
      other.offset == offset &&
      other.color == color;

  @override
  int get hashCode => Object.hash(offset, color);
}

/// A linear gradient in the local coordinate space of its painted target.
///
/// The line's [start] and [end] are explicit document semantics. They are not
/// derived from artboard size, a renderer, or an editor control. Stops are
/// intentionally preserved as authored, including duplicate offsets for hard
/// transitions; document validation checks that the list is usable.
final class LinearGradientSpec {
  factory LinearGradientSpec({
    required Vec2 start,
    required Vec2 end,
    required Iterable<GradientStop> stops,
  }) => LinearGradientSpec._(
    start: start,
    end: end,
    stops: List<GradientStop>.unmodifiable(stops),
  );

  const LinearGradientSpec._({
    required this.start,
    required this.end,
    required this.stops,
  });

  final Vec2 start;
  final Vec2 end;
  final List<GradientStop> stops;

  static const transparent = LinearGradientSpec._(
    start: Vec2(0, 0),
    end: Vec2(1, 0),
    stops: <GradientStop>[
      GradientStop(offset: 0, color: 0x00000000),
      GradientStop(offset: 1, color: 0x00000000),
    ],
  );

  LinearGradientSpec copyWith({
    Vec2? start,
    Vec2? end,
    Iterable<GradientStop>? stops,
  }) => LinearGradientSpec(
    start: start ?? this.start,
    end: end ?? this.end,
    stops: stops ?? this.stops,
  );

  Map<String, dynamic> toJson() => {
    'start': start.toJson(),
    'end': end.toJson(),
    'stops': [for (final stop in stops) stop.toJson()],
  };

  factory LinearGradientSpec.fromJson(Map<String, dynamic> json) {
    final start = json['start'];
    final end = json['end'];
    final stops = json['stops'];

    if (start is! Map || end is! Map || stops is! List) {
      throw const FormatException(
        'LinearGradientSpec requires start, end, and stops fields.',
      );
    }

    return LinearGradientSpec(
      start: Vec2.fromJson(start.cast<String, dynamic>()),
      end: Vec2.fromJson(end.cast<String, dynamic>()),
      stops: stops.map((raw) {
        if (raw is! Map) {
          throw const FormatException('LinearGradientSpec.stops must be maps');
        }
        return GradientStop.fromJson(raw.cast<String, dynamic>());
      }),
    );
  }

  @override
  String toString() =>
      'LinearGradientSpec(start=$start, end=$end, stops=$stops)';

  @override
  bool operator ==(Object other) =>
      other is LinearGradientSpec &&
      other.start == start &&
      other.end == end &&
      _sameGradientStops(other.stops, stops);

  @override
  int get hashCode => Object.hash(start, end, Object.hashAll(stops));
}

bool _sameGradientStops(List<GradientStop> a, List<GradientStop> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;

  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
