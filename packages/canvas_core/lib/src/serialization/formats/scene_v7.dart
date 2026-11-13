import 'package:canvas_core/src/serialization/scene_format.dart';

/// Checks wire structure before generated decoding can discard unknown fields
/// or coerce integers. Geometry and gradients have their own strict decoders.
void validateSceneV7Json(Map<String, Object?> json) {
  const version = currentCanvasSceneFormatVersion;
  if (json['sceneFormatVersion'] is! int ||
      json['sceneFormatVersion'] != version) {
    _fail(
      '/sceneFormatVersion',
      'Expected sceneFormatVersion $version. Use canvas_scene_upgrade explicitly for historical scenes.',
    );
  }
  _keys(
    json,
    {
      'sceneFormatVersion',
      'artboardSize',
      'backgroundFill',
      'backgroundOpacity',
      'assets',
      'children',
    },
    '',
    requiredFields: [
      'artboardSize',
      'backgroundFill',
      'backgroundOpacity',
      'children',
    ],
  );
  _size(json['artboardSize'], '/artboardSize');
  _fill(json['backgroundFill'], '/backgroundFill');
  _number(json['backgroundOpacity'], '/backgroundOpacity');
  if (json['assets'] != null) {
    final assets = _object(json['assets'], '/assets');
    for (final id in assets.keys) {
      final path = '/assets/$id';
      final asset = _object(assets[id], path);
      _keys(
        asset,
        {'sourceRef', 'intrinsicSize'},
        path,
        requiredFields: ['sourceRef', 'intrinsicSize'],
      );
      _string(asset['sourceRef'], '$path/sourceRef');
      _size(asset['intrinsicSize'], '$path/intrinsicSize');
    }
  }
  final children = _list(json['children'], '/children');
  for (var index = 0; index < children.length; index++) {
    _node(children[index], '/children/$index');
  }
}

void _node(Object? raw, String path) {
  final node = _object(raw, path);
  final fields = switch (node['type']) {
    'group' => {'children'},
    'path' => {'geometry', 'fillRule', 'appearance'},
    'text' => {
      'text',
      'fontFamily',
      'fontWeight',
      'fontSize',
      'letterSpacing',
      'appearance',
    },
    'icon' => {'iconRef', 'sizePx', 'appearance'},
    'image' => {'assetId', 'size', 'fit', 'align'},
    _ => _fail('$path/type', 'Expected a supported node type.'),
  };
  _keys(
    node,
    {'type', 'id', 'name', 'xf', ...fields},
    path,
    requiredFields: ['id'],
  );
  _string(node['id'], '$path/id');
  if (node['name'] != null) _string(node['name'], '$path/name');
  if (node.containsKey('xf')) _transform(node['xf'], '$path/xf');
  if (node['type'] == 'group') {
    _required(node, 'children', path);
    final children = _list(node['children'], '$path/children');
    for (var index = 0; index < children.length; index++) {
      _node(children[index], '$path/children/$index');
    }
    return;
  }

  switch (node['type']) {
    case 'path':
      _object(node['geometry'], '$path/geometry');
      if (node['fillRule'] != null) {
        _enum(node['fillRule'], {'nonZero', 'evenOdd'}, '$path/fillRule');
      }
      _appearance(node['appearance'], '$path/appearance');
    case 'text':
      _string(node['text'], '$path/text');
      _string(node['fontFamily'], '$path/fontFamily');
      _integer(node['fontWeight'], '$path/fontWeight');
      _number(node['fontSize'], '$path/fontSize');
      if (node['letterSpacing'] != null) {
        _number(node['letterSpacing'], '$path/letterSpacing');
      }
      _appearance(node['appearance'], '$path/appearance');
    case 'icon':
      _string(node['iconRef'], '$path/iconRef');
      if (node['sizePx'] != null) _number(node['sizePx'], '$path/sizePx');
      _appearance(node['appearance'], '$path/appearance');
    case 'image':
      if (node['assetId'] != null) _string(node['assetId'], '$path/assetId');
      _size(node['size'], '$path/size');
      if (node['fit'] != null) {
        _enum(node['fit'], {'contain', 'cover', 'fill'}, '$path/fit');
      }
      if (node['align'] != null) _point(node['align'], '$path/align');
  }
}

void _transform(Object? raw, String path) {
  if (raw is! List ||
      raw.length != 6 ||
      raw.any((value) => value is! num || !value.toDouble().isFinite)) {
    _fail(path, 'Expected exactly six finite affine coefficients.');
  }
}

void _appearance(Object? raw, String path) {
  final value = _object(raw, path);
  _keys(
    value,
    {'foreground', 'stroke', 'underlays'},
    path,
    requiredFields: ['foreground'],
  );
  _fill(value['foreground'], '$path/foreground');
  if (value['stroke'] != null) {
    final strokePath = '$path/stroke';
    final stroke = _object(value['stroke'], strokePath);
    _keys(
      stroke,
      {'color', 'width', 'cap', 'join', 'miterLimit', 'dash'},
      strokePath,
      requiredFields: ['color'],
    );
    _integer(stroke['color'], '$strokePath/color');
    for (final name in ['width', 'miterLimit']) {
      if (stroke[name] != null) _number(stroke[name], '$strokePath/$name');
    }
    if (stroke['cap'] != null)
      _enum(stroke['cap'], {'butt', 'round', 'square'}, '$strokePath/cap');
    if (stroke['join'] != null)
      _enum(stroke['join'], {'miter', 'round', 'bevel'}, '$strokePath/join');
    if (stroke['dash'] != null) {
      final dash = _list(stroke['dash'], '$strokePath/dash');
      for (var index = 0; index < dash.length; index++) {
        _number(dash[index], '$strokePath/dash/$index');
      }
    }
  }
  if (value['underlays'] == null) return;
  final underlays = _list(value['underlays'], '$path/underlays');
  for (var index = 0; index < underlays.length; index++) {
    final itemPath = '$path/underlays/$index';
    final underlay = _object(underlays[index], itemPath);
    _keys(
      underlay,
      {'type', 'id', 'enabled', 'offset', 'blurSigma', 'color'},
      itemPath,
      requiredFields: ['type', 'id', 'offset', 'color'],
    );
    _enum(underlay['type'], {'shadow'}, '$itemPath/type');
    _string(underlay['id'], '$itemPath/id');
    if (underlay['enabled'] != null)
      _bool(underlay['enabled'], '$itemPath/enabled');
    _point(underlay['offset'], '$itemPath/offset');
    if (underlay['blurSigma'] != null)
      _number(underlay['blurSigma'], '$itemPath/blurSigma');
    _integer(underlay['color'], '$itemPath/color');
  }
}

void _fill(Object? raw, String path) {
  final fill = _object(raw, path);
  _required(fill, 'type', path);
  _enum(fill['type'], {'none', 'solid', 'gradient'}, '$path/type');
  switch (fill['type']) {
    case 'none':
      _keys(fill, {'type'}, path);
    case 'solid':
      _keys(fill, {'type', 'color'}, path, requiredFields: ['color']);
      _integer(fill['color'], '$path/color');
    case 'gradient':
      _keys(fill, {'type', 'grad'}, path, requiredFields: ['grad']);
    // The gradient decoder owns its strict structure and primitive types.
  }
}

void _point(Object? raw, String path) {
  final value = _object(raw, path);
  _keys(value, {'x', 'y'}, path, requiredFields: ['x', 'y']);
  _number(value['x'], '$path/x');
  _number(value['y'], '$path/y');
}

void _size(Object? raw, String path) {
  final value = _object(raw, path);
  _keys(value, {'w', 'h'}, path, requiredFields: ['w', 'h']);
  _number(value['w'], '$path/w');
  _number(value['h'], '$path/h');
}

void _keys(
  Map<String, Object?> object,
  Set<String> allowed,
  String path, {
  List<String> requiredFields = const [],
}) {
  for (final key in object.keys) {
    if (!allowed.contains(key)) {
      _fail('$path/$key', 'Unsupported scene field.');
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

void _bool(Object? raw, String path) {
  if (raw is! bool) _fail(path, 'Expected a boolean.');
}

void _enum(Object? raw, Set<String> values, String path) {
  _string(raw, path);
  if (!values.contains(raw)) {
    _fail(path, 'Unsupported value: $raw.');
  }
}

Never _fail(String path, String message) =>
    throw FormatException('$path: $message');
