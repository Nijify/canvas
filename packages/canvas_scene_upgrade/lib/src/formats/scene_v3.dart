import 'scene_trs_wire.dart';

/// Historical v3 wire format, independent of current runtime geometry.
const int canvasSceneFormatV3 = 3;

void validateSceneV3Json(Map<String, Object?> json) =>
    validateSceneV3Wire(json, validateSource: _source);

void _source(Object? raw, String path) {
  final source = _object(raw, path);
  _required(source, 'kind', path);
  _enum(source['kind'], {
    'commands',
    'polyline',
    'rect',
    'roundRect',
    'pill',
    'underline',
    'ellipse',
    'circle',
    'regularPolygon',
    'star',
  }, '$path/kind');
  // The historical v3 converter owns structured-command validation.
  if (source['kind'] == 'commands') return;
  final parameters = switch (source['kind']) {
    'polyline' => ['points'],
    'rect' || 'pill' => ['w', 'h'],
    'roundRect' => ['w', 'h', 'rx', 'ry'],
    'underline' => ['w', 'thickness'],
    'ellipse' => ['rx', 'ry'],
    'circle' => ['r'],
    'regularPolygon' => ['sides', 'r'],
    'star' => ['points', 'rOuter', 'rInner'],
    _ => throw StateError('Validated path source kind.'),
  };
  final hasRotation =
      source['kind'] == 'regularPolygon' || source['kind'] == 'star';
  _keys(
    source,
    {'kind', ...parameters, if (hasRotation) 'rotation'},
    path,
    requiredFields: parameters,
  );
  if (hasRotation && source['rotation'] != null)
    _number(source['rotation'], '$path/rotation');
  if (source['kind'] == 'polyline') {
    final points = _list(source['points'], '$path/points');
    for (var index = 0; index < points.length; index++) {
      if (points[index] != null) _point(points[index], '$path/points/$index');
    }
  } else {
    for (final name in parameters) {
      if (name == 'sides' || name == 'points') {
        _integer(source[name], '$path/$name');
      } else {
        _number(source[name], '$path/$name');
      }
    }
  }
}

void _point(Object? raw, String path) {
  final value = _object(raw, path);
  _keys(value, {'x', 'y'}, path, requiredFields: ['x', 'y']);
  _number(value['x'], '$path/x');
  _number(value['y'], '$path/y');
}

void _keys(
  Map<String, Object?> object,
  Set<String> allowed,
  String path, {
  List<String> requiredFields = const [],
}) {
  for (final key in object.keys) {
    if (!allowed.contains(key)) {
      _fail('$path/$key', 'This field is not part of scene format v3.');
    }
  }
  for (final name in requiredFields) _required(object, name, path);
}

void _required(Map<String, Object?> object, String name, String path) {
  if (!object.containsKey(name)) {
    _fail('$path/$name', 'Required field is missing.');
  }
}

Map<String, Object?> _object(Object? raw, String path) {
  if (raw is! Map || raw.keys.any((key) => key is! String)) {
    _fail(path, 'Expected an object with string keys.');
  }
  return Map<String, Object?>.from(raw);
}

List<Object?> _list(Object? raw, String path) {
  if (raw is! List) _fail(path, 'Expected a list.');
  return raw;
}

void _number(Object? raw, String path) {
  if (raw is! num) _fail(path, 'Expected a number.');
}

void _integer(Object? raw, String path) {
  if (raw is! int) _fail(path, 'Expected an integer.');
}

void _string(Object? raw, String path) {
  if (raw is! String) _fail(path, 'Expected a string.');
}

void _enum(Object? raw, Set<String> values, String path) {
  _string(raw, path);
  if (!values.contains(raw)) {
    _fail(path, 'Unsupported value: $raw.');
  }
}

Never _fail(String path, String message) =>
    throw FormatException('$path: $message');
