// Path: lib/src/path/path_source.dart

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/serialization/json_vec2.dart';

sealed class PathSource {
  const PathSource();
  Map<String, Object?> toJson();
  static PathSource fromJson(Map<String, Object?> json) {
    final k = json['kind'];
    switch (k) {
      case 'polyline':
        return PolylineSource.fromJson(json);
      case 'rect':
        return RectSource.fromJson(json);
      case 'roundRect':
        return RoundRectSource.fromJson(json);
      case 'pill':
        return PillSource.fromJson(json);
      case 'underline':
        return UnderlineSource.fromJson(json);
      case 'ellipse':
        return EllipseSource.fromJson(json);
      case 'svg':
        return SvgPathSource.fromJson(json);
      case 'circle':
        return CircleSource.fromJson(json);
      case 'regularPolygon':
        return RegularPolygonSource.fromJson(json);
      case 'star':
        return StarSource.fromJson(json);
      default:
        throw FormatException('Unknown PathSource kind: $k');
    }
  }
}

class PolylineSource extends PathSource {
  final List<Vec2?> points; // same as today; null breaks
  const PolylineSource(this.points);

  factory PolylineSource.fromJson(Map<String, Object?> m) =>
      PolylineSource(vec2ListNullableFromJson(m['points']));

  @override
  Map<String, Object?> toJson() => {
    'kind': 'polyline',
    'points': vec2ListNullableToJson(points),
  };
}

// NEW sources
class CircleSource extends PathSource {
  final double r;
  const CircleSource(this.r);
  factory CircleSource.fromJson(Map<String, Object?> m) =>
      CircleSource((m['r'] as num).toDouble());
  @override
  Map<String, Object?> toJson() => {'kind': 'circle', 'r': r};
}

class RegularPolygonSource extends PathSource {
  final int sides;
  final double r; // radius
  final double rotation; // deg, optional
  const RegularPolygonSource(this.sides, this.r, {this.rotation = 0});
  factory RegularPolygonSource.fromJson(Map<String, Object?> m) =>
      RegularPolygonSource(
        (m['sides'] as num).toInt(),
        (m['r'] as num).toDouble(),
        rotation: (m['rotation'] as num?)?.toDouble() ?? 0,
      );
  @override
  Map<String, Object?> toJson() => {
    'kind': 'regularPolygon',
    'sides': sides,
    'r': r,
    'rotation': rotation,
  };
}

class StarSource extends PathSource {
  final int points; // >=3
  final double rOuter; // outer radius
  final double rInner; // inner radius (0..rOuter)
  final double rotation; // deg
  const StarSource(this.points, this.rOuter, this.rInner, {this.rotation = 0});
  factory StarSource.fromJson(Map<String, Object?> m) => StarSource(
    (m['points'] as num).toInt(),
    (m['rOuter'] as num).toDouble(),
    (m['rInner'] as num).toDouble(),
    rotation: (m['rotation'] as num?)?.toDouble() ?? 0,
  );
  @override
  Map<String, Object?> toJson() => {
    'kind': 'star',
    'points': points,
    'rOuter': rOuter,
    'rInner': rInner,
    'rotation': rotation,
  };
}

class RectSource extends PathSource {
  final double w, h;
  const RectSource(this.w, this.h);
  factory RectSource.fromJson(Map<String, Object?> m) =>
      RectSource((m['w'] as num).toDouble(), (m['h'] as num).toDouble());
  @override
  Map<String, Object?> toJson() => {'kind': 'rect', 'w': w, 'h': h};
}

class RoundRectSource extends PathSource {
  final double w, h, rx, ry;
  const RoundRectSource(this.w, this.h, this.rx, this.ry);
  factory RoundRectSource.fromJson(Map<String, Object?> m) => RoundRectSource(
    (m['w'] as num).toDouble(),
    (m['h'] as num).toDouble(),
    (m['rx'] as num).toDouble(),
    (m['ry'] as num).toDouble(),
  );
  @override
  Map<String, Object?> toJson() => {
    'kind': 'roundRect',
    'w': w,
    'h': h,
    'rx': rx,
    'ry': ry,
  };
}

class PillSource extends PathSource {
  // convenience alias for full-height rx
  final double w, h;
  const PillSource(this.w, this.h);
  factory PillSource.fromJson(Map<String, Object?> m) =>
      PillSource((m['w'] as num).toDouble(), (m['h'] as num).toDouble());
  @override
  Map<String, Object?> toJson() => {'kind': 'pill', 'w': w, 'h': h};
}

class UnderlineSource extends PathSource {
  // filled rect line
  final double w, thickness;
  const UnderlineSource(this.w, this.thickness);
  factory UnderlineSource.fromJson(Map<String, Object?> m) => UnderlineSource(
    (m['w'] as num).toDouble(),
    (m['thickness'] as num).toDouble(),
  );
  @override
  Map<String, Object?> toJson() => {
    'kind': 'underline',
    'w': w,
    'thickness': thickness,
  };
}

class EllipseSource extends PathSource {
  final double rx, ry;
  const EllipseSource(this.rx, this.ry);
  factory EllipseSource.fromJson(Map<String, Object?> m) =>
      EllipseSource((m['rx'] as num).toDouble(), (m['ry'] as num).toDouble());
  @override
  Map<String, Object?> toJson() => {'kind': 'ellipse', 'rx': rx, 'ry': ry};
}

class SvgPathSource extends PathSource {
  final String d; // SVG path string
  const SvgPathSource(this.d);
  factory SvgPathSource.fromJson(Map<String, Object?> m) =>
      SvgPathSource(m['d'] as String);
  @override
  Map<String, Object?> toJson() => {'kind': 'svg', 'd': d};
}
