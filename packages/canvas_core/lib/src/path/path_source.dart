import 'package:canvas_core/src/foundation/core_types.dart' show Vec2;
import 'package:canvas_core/src/path/path_ir.dart';
import 'package:canvas_core/src/path/svg_path_codec.dart';

/// The seven SVG-aligned authored geometry variants. Sources contain no paint.
sealed class PathSource {
  const PathSource();
  Map<String, Object?> toJson();

  static PathSource fromJson(Map<String, Object?> json) {
    final kind = json['kind'];
    final (requiredKeys, optionalKeys) = switch (kind) {
      'rect' => (const ['width', 'height'], const ['x', 'y', 'rx', 'ry']),
      'circle' => (const ['r'], const ['cx', 'cy']),
      'ellipse' => (const ['rx', 'ry'], const ['cx', 'cy']),
      'line' => (const <String>[], const ['x1', 'y1', 'x2', 'y2']),
      'polyline' || 'polygon' => (const ['points'], const <String>[]),
      'path' => (const ['d'], const <String>[]),
      _ => throw FormatException('Unsupported v4 geometry kind: $kind'),
    };
    final allowed = {'kind', ...requiredKeys, ...optionalKeys};
    if (json.keys.any((key) => !allowed.contains(key)) ||
        requiredKeys.any((key) => !json.containsKey(key))) {
      throw FormatException('Invalid fields for $kind geometry.');
    }
    double number(String key, [double fallback = 0]) {
      if (!json.containsKey(key)) return fallback;
      final value = json[key];
      if (value is! num || !value.toDouble().isFinite) {
        throw FormatException('$kind.$key must be a finite number.');
      }
      return value.toDouble();
    }

    double? optional(String key) => json.containsKey(key) ? number(key) : null;
    String string(String key) {
      final value = json[key];
      if (value is! String)
        throw FormatException('$kind.$key must be a string.');
      return value;
    }

    try {
      final PathSource source = switch (kind) {
        'rect' => RectSource(
          x: number('x'),
          y: number('y'),
          width: number('width'),
          height: number('height'),
          rx: optional('rx'),
          ry: optional('ry'),
        ),
        'circle' => CircleSource(
          number('r'),
          cx: number('cx'),
          cy: number('cy'),
        ),
        'ellipse' => EllipseSource(
          number('rx'),
          number('ry'),
          cx: number('cx'),
          cy: number('cy'),
        ),
        'line' => LineSource(
          x1: number('x1'),
          y1: number('y1'),
          x2: number('x2'),
          y2: number('y2'),
        ),
        'polyline' => PolylineSource(parseSvgPoints(string('points'))),
        'polygon' => PolygonSource(parseSvgPoints(string('points'))),
        'path' => GeneralPathSource(parseSvgPathData(string('d'))),
        _ => throw StateError('Validated kind.'),
      };
      requirePathSourceIntegrity(source);
      return source;
    } on ArgumentError catch (error) {
      throw FormatException('Invalid $kind geometry: ${error.message}');
    }
  }
}

final class RectSource extends PathSource {
  const RectSource({
    this.x = 0,
    this.y = 0,
    required this.width,
    required this.height,
    this.rx,
    this.ry,
  });
  final double x, y, width, height;
  // Null preserves SVG's fallback-to-the-other-radius authoring semantics.
  final double? rx, ry;
  @override
  Map<String, Object?> toJson() => {
    'kind': 'rect',
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    if (rx != null) 'rx': rx,
    if (ry != null) 'ry': ry,
  };
}

final class CircleSource extends PathSource {
  const CircleSource(this.r, {this.cx = 0, this.cy = 0});
  final double cx, cy, r;
  @override
  Map<String, Object?> toJson() => {
    'kind': 'circle',
    'cx': cx,
    'cy': cy,
    'r': r,
  };
}

final class EllipseSource extends PathSource {
  const EllipseSource(this.rx, this.ry, {this.cx = 0, this.cy = 0});
  final double cx, cy, rx, ry;
  @override
  Map<String, Object?> toJson() => {
    'kind': 'ellipse',
    'cx': cx,
    'cy': cy,
    'rx': rx,
    'ry': ry,
  };
}

final class LineSource extends PathSource {
  const LineSource({this.x1 = 0, this.y1 = 0, this.x2 = 0, this.y2 = 0});
  final double x1, y1, x2, y2;
  @override
  Map<String, Object?> toJson() => {
    'kind': 'line',
    'x1': x1,
    'y1': y1,
    'x2': x2,
    'y2': y2,
  };
}

final class PolylineSource extends PathSource {
  PolylineSource(List<Vec2> points) : points = List.unmodifiable(points) {
    _requirePoints(this.points);
  }
  final List<Vec2> points;
  @override
  Map<String, Object?> toJson() => {
    'kind': 'polyline',
    'points': writeSvgPoints(points),
  };
}

final class PolygonSource extends PathSource {
  PolygonSource(List<Vec2> points) : points = List.unmodifiable(points) {
    _requirePoints(this.points);
  }
  final List<Vec2> points;
  @override
  Map<String, Object?> toJson() => {
    'kind': 'polygon',
    'points': writeSvgPoints(points),
  };
}

final class GeneralPathSource extends PathSource {
  const GeneralPathSource(this.geometry);
  factory GeneralPathSource.fromSvg(String d) =>
      GeneralPathSource(parseSvgPathData(d));
  final PathIR geometry;
  @override
  Map<String, Object?> toJson() => {
    'kind': 'path',
    'd': writeSvgPathData(geometry),
  };
}

void _requirePoints(List<Vec2> points) {
  for (final point in points) {
    if (!point.x.isFinite || !point.y.isFinite) {
      throw ArgumentError('Points must have finite coordinates.');
    }
  }
}

/// Shared semantic checks for programmatic sources, decoding, and compilation.
void requirePathSourceIntegrity(PathSource source) {
  void finite(double value) {
    if (!value.isFinite) throw ArgumentError('Geometry must be finite.');
  }

  void nonnegative(double value) {
    finite(value);
    if (value < 0)
      throw ArgumentError('Dimensions and radii must be nonnegative.');
  }

  switch (source) {
    case RectSource(
      :final x,
      :final y,
      :final width,
      :final height,
      :final rx,
      :final ry,
    ):
      finite(x);
      finite(y);
      nonnegative(width);
      nonnegative(height);
      if (rx != null) nonnegative(rx);
      if (ry != null) nonnegative(ry);
      finite(x + width);
      finite(y + height);
    case CircleSource(:final cx, :final cy, :final r):
      finite(cx);
      finite(cy);
      nonnegative(r);
      finite(cx - r);
      finite(cx + r);
      finite(cy - r);
      finite(cy + r);
    case EllipseSource(:final cx, :final cy, :final rx, :final ry):
      finite(cx);
      finite(cy);
      nonnegative(rx);
      nonnegative(ry);
      finite(cx - rx);
      finite(cx + rx);
      finite(cy - ry);
      finite(cy + ry);
    case LineSource(:final x1, :final y1, :final x2, :final y2):
      finite(x1);
      finite(y1);
      finite(x2);
      finite(y2);
    case PolylineSource() || PolygonSource() || GeneralPathSource():
      // Collection geometry is validated and frozen at construction.
      break;
  }
}
