import 'dart:math' as math;

import 'package:canvas_core/src/foundation/core_types.dart' show Vec2;
import 'package:canvas_core/src/path/path_ir.dart';
import 'package:canvas_core/src/path/svg_path_codec.dart';
import 'package:canvas_core/src/serialization/formats/scene_v3.dart';
import 'package:canvas_core/src/serialization/formats/scene_v4.dart';
import 'package:canvas_core/src/serialization/serializers.dart';

/// Converts historical v3 JSON without constructing retired runtime sources.
/// Input containers are copied. Transforms, appearance, IDs, and authoring
/// metadata are retained. Quadratic control-hull bounds can change after exact
/// cubic conversion, so center-derived pivots can change in transformed scenes.
Map<String, Object?> convertCanvasSceneV3ToV4(Map<String, Object?> v3) {
  validateSceneV3Json(v3);
  final result = _copy(v3) as Map<String, Object?>;
  result['sceneFormatVersion'] = canvasSceneFormatV4;
  void visit(List children) {
    for (final raw in children) {
      final node = raw as Map<String, Object?>;
      if (node['runtimeType'] == 'group') {
        visit(node['children'] as List);
      } else if (node['runtimeType'] == 'path') {
        final data = node['data'] as Map<String, Object?>;
        data['source'] = _source(data['source'] as Map<String, Object?>);
      }
    }
  }

  visit(result['children'] as List);
  decodeCanvasScene(result);
  return result;
}

Map<String, Object?> _source(Map<String, Object?> source) {
  double n(String key, [double fallback = 0]) {
    final value = source[key];
    if (value == null && !source.containsKey(key)) return fallback;
    if (value is! num || !value.toDouble().isFinite) {
      throw FormatException('v3 source.$key must be finite.');
    }
    return value.toDouble();
  }

  Map<String, Object?> rect(
    double width,
    double height, [
    double? rx,
    double? ry,
  ]) => {
    'kind': 'rect',
    'x': -width / 2,
    'y': -height / 2,
    'width': width,
    'height': height,
    if (rx != null) 'rx': rx,
    if (ry != null) 'ry': ry,
  };
  switch (source['kind']) {
    case 'rect':
      return rect(n('w'), n('h'));
    case 'roundRect':
      return rect(n('w'), n('h'), n('rx'), n('ry'));
    case 'pill':
      return rect(n('w'), n('h'), n('h') / 2, n('h') / 2);
    case 'underline':
      return rect(n('w'), n('thickness'));
    case 'circle':
      return {'kind': 'circle', 'cx': 0, 'cy': 0, 'r': n('r')};
    case 'ellipse':
      return {
        'kind': 'ellipse',
        'cx': 0,
        'cy': 0,
        'rx': n('rx'),
        'ry': n('ry'),
      };
    case 'regularPolygon':
    case 'star':
      final star = source['kind'] == 'star';
      final count = source[star ? 'points' : 'sides'];
      if (count is! int || count < 3) {
        throw const FormatException(
          'v3 polygon/star count must be at least 3.',
        );
      }
      final outer = n(star ? 'rOuter' : 'r');
      final inner = star ? n('rInner') : outer;
      if (outer < 0 || inner < 0 || inner > outer) {
        throw const FormatException('Invalid v3 polygon/star radii.');
      }
      final rotation = n('rotation') * math.pi / 180;
      final total = star ? count * 2 : count;
      final points = <Vec2>[
        for (var i = 0; i < total; i++)
          Vec2(
            (star && i.isOdd ? inner : outer) *
                math.cos(rotation + i * 2 * math.pi / total),
            (star && i.isOdd ? inner : outer) *
                math.sin(rotation + i * 2 * math.pi / total),
          ),
      ];
      return {'kind': 'polygon', 'points': writeSvgPoints(points)};
    case 'polyline':
      final contours = <List<Vec2>>[];
      var current = <Vec2>[];
      for (final raw in source['points'] as List) {
        if (raw == null) {
          if (current.isNotEmpty) contours.add(current);
          current = <Vec2>[];
        } else {
          current.add(_point(raw));
        }
      }
      if (current.isNotEmpty) contours.add(current);
      if (contours.length == 1) {
        final points = contours.single;
        if (points.length == 2)
          return {
            'kind': 'line',
            'x1': points[0].x,
            'y1': points[0].y,
            'x2': points[1].x,
            'y2': points[1].y,
          };
        return {'kind': 'polyline', 'points': writeSvgPoints(points)};
      }
      return {
        'kind': 'path',
        'd': writeSvgPathData(
          PathIR([
            for (final points in contours) ...[
              PathCmd.moveTo(points.first),
              for (final point in points.skip(1)) PathCmd.lineTo(point),
            ],
          ]),
        ),
      };
    case 'commands':
      return {'kind': 'path', 'd': writeSvgPathData(_commands(source))};
    default:
      throw FormatException('Unsupported v3 source: ${source['kind']}');
  }
}

PathIR _commands(Map<String, Object?> source) {
  if (source.length != 2 || source['commands'] is! List) {
    throw const FormatException('Invalid v3 commands source.');
  }
  final commands = <PathCmd>[];
  var current = Vec2.zero;
  for (final raw in source['commands'] as List) {
    if (raw is! Map || raw.keys.any((key) => key is! String)) {
      throw const FormatException('Expected a v3 command object.');
    }
    final names = switch (raw['verb']) {
      'moveTo' || 'lineTo' => const ['p'],
      'quadTo' => const ['c1', 'p'],
      'cubicTo' => const ['c1', 'c2', 'p'],
      'close' => const <String>[],
      _ => throw const FormatException('Unsupported v3 command.'),
    };
    if (raw.length != names.length + 1 ||
        names.any((key) => !raw.containsKey(key))) {
      throw const FormatException('Invalid v3 command fields.');
    }
    final end = raw['verb'] == 'close' ? Vec2.zero : _point(raw['p']);
    commands.add(switch (raw['verb']) {
      'moveTo' => PathCmd.moveTo(end),
      'lineTo' => PathCmd.lineTo(end),
      'quadTo' => PathCmd.cubicTo(
        current + (_point(raw['c1']) - current) * (2 / 3),
        end + (_point(raw['c1']) - end) * (2 / 3),
        end,
      ),
      'cubicTo' => PathCmd.cubicTo(_point(raw['c1']), _point(raw['c2']), end),
      'close' => PathCmd.close(),
      _ => throw StateError('Validated v3 verb.'),
    });
    current = end;
  }
  try {
    return PathIR(commands);
  } on ArgumentError catch (error) {
    throw FormatException('Invalid v3 commands: ${error.message}');
  }
}

Vec2 _point(Object? raw) {
  if (raw is! Map ||
      raw.length != 2 ||
      !raw.containsKey('x') ||
      !raw.containsKey('y')) {
    throw const FormatException('Expected a v3 point object.');
  }
  double number(String key) {
    final value = raw[key];
    if (value is! num || !value.toDouble().isFinite) {
      throw const FormatException('v3 points must be finite.');
    }
    return value.toDouble();
  }

  return Vec2(number('x'), number('y'));
}

Object? _copy(Object? value) {
  if (value is Map)
    return <String, Object?>{
      for (final entry in value.entries)
        entry.key as String: _copy(entry.value),
    };
  if (value is List) return <Object?>[for (final item in value) _copy(item)];
  return value;
}
