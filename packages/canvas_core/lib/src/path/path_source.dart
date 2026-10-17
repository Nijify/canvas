// Path: lib/src/path/path_source.dart

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/path/path_ir.dart' show PathCmd, PathVerb;
import 'package:canvas_core/src/serialization/json_vec2.dart';

sealed class PathSource {
  const PathSource();
  Map<String, Object?> toJson();
  static PathSource fromJson(Map<String, Object?> json) {
    final k = json['kind'];
    switch (k) {
      case 'commands':
        return CommandPathSource.fromJson(json);
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
        throw const FormatException(
          'SVG path strings are unsupported. Normalize to a commands source '
          'before loading.',
        );
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

/// Normalized, absolute geometry in source coordinates, with no paint data.
///
/// Supports multiple contours and open contours. Each contour starts with
/// moveTo; close ends it, so subsequent drawing requires another moveTo.
/// Empty geometry is valid. Curves are polynomial quadratics or cubics;
/// importers must convert arcs before constructing this source.
final class CommandPathSource extends PathSource {
  final List<PathCmd> commands;

  CommandPathSource(List<PathCmd> commands)
    : commands = List<PathCmd>.unmodifiable(commands) {
    var contourOpen = false;
    for (var index = 0; index < this.commands.length; index++) {
      final command = this.commands[index];
      if (command.verb == PathVerb.moveTo) {
        contourOpen = true;
      } else if (!contourOpen) {
        throw ArgumentError('commands[$index] requires a preceding moveTo.');
      }
      if (command.verb == PathVerb.close) {
        contourOpen = false;
        continue;
      }
      _requireFinite(command.p, 'commands[$index].p');
      if (command.c1 != null) {
        _requireFinite(command.c1!, 'commands[$index].c1');
      }
      if (command.c2 != null) {
        _requireFinite(command.c2!, 'commands[$index].c2');
      }
    }
  }

  factory CommandPathSource.fromJson(Map<String, Object?> json) {
    _requireKeys(json, const {'kind', 'commands'}, 'source');
    if (json['kind'] != 'commands' || json['commands'] is! List) {
      throw const FormatException('Expected a commands path source.');
    }
    final values = json['commands'] as List;
    final commands = <PathCmd>[];
    for (var index = 0; index < values.length; index++) {
      final path = 'commands[$index]';
      final value = _object(values[index], path);
      final verb = switch (value['verb']) {
        'moveTo' => PathVerb.moveTo,
        'lineTo' => PathVerb.lineTo,
        'quadTo' => PathVerb.quadTo,
        'cubicTo' => PathVerb.cubicTo,
        'close' => PathVerb.close,
        _ => throw FormatException('$path has an unsupported verb.'),
      };
      final pointNames = switch (verb) {
        PathVerb.moveTo || PathVerb.lineTo => const ['p'],
        PathVerb.quadTo => const ['c1', 'p'],
        PathVerb.cubicTo => const ['c1', 'c2', 'p'],
        PathVerb.close => const <String>[],
      };
      _requireKeys(value, {'verb', ...pointNames}, path);
      Vec2 point(String name) => _point(value[name], '$path.$name');
      commands.add(switch (verb) {
        PathVerb.moveTo => PathCmd.moveTo(point('p')),
        PathVerb.lineTo => PathCmd.lineTo(point('p')),
        PathVerb.quadTo => PathCmd.quadTo(point('c1'), point('p')),
        PathVerb.cubicTo => PathCmd.cubicTo(
          point('c1'),
          point('c2'),
          point('p'),
        ),
        PathVerb.close => PathCmd.close(),
      });
    }
    try {
      return CommandPathSource(commands);
    } on ArgumentError catch (error) {
      throw FormatException(error.message?.toString() ?? 'Invalid commands.');
    }
  }

  @override
  Map<String, Object?> toJson() => {
    'kind': 'commands',
    'commands': [
      for (final command in commands)
        <String, Object?>{
          'verb': command.verb.name,
          if (command.c1 != null) 'c1': command.c1!.toJson(),
          if (command.c2 != null) 'c2': command.c2!.toJson(),
          if (command.verb != PathVerb.close) 'p': command.p.toJson(),
        },
    ],
  };

  static Map<String, Object?> _object(Object? value, String path) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw FormatException('$path must be an object.');
    }
    return Map<String, Object?>.from(value);
  }

  static void _requireKeys(
    Map<String, Object?> value,
    Set<String> keys,
    String path,
  ) {
    if (value.length != keys.length || !keys.every(value.containsKey)) {
      throw FormatException('$path must contain exactly ${keys.join(', ')}.');
    }
  }

  static Vec2 _point(Object? value, String path) {
    final point = _object(value, path);
    _requireKeys(point, const {'x', 'y'}, path);
    double coordinate(String axis) {
      final number = point[axis];
      if (number is! num || !number.toDouble().isFinite) {
        throw FormatException('$path.$axis must be a finite number.');
      }
      return number.toDouble();
    }

    return Vec2(coordinate('x'), coordinate('y'));
  }

  static void _requireFinite(Vec2 point, String path) {
    if (!point.x.isFinite || !point.y.isFinite) {
      throw ArgumentError('$path must have finite coordinates.');
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
