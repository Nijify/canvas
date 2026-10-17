/// Required path sources and shared authored appearance.
const int canvasSceneFormatV3 = 3;

/// Checks wire structure and primitive types before generated decoding can
/// discard unknown fields or coerce integer properties. Runtime validation
/// owns the shared semantic rules after decoding.
void validateSceneV3Json(Map<String, Object?> json) {
  if (json['sceneFormatVersion'] is! int ||
      json['sceneFormatVersion'] != canvasSceneFormatV3) {
    _fail(
      '/sceneFormatVersion',
      'Expected sceneFormatVersion 3. Upgrade historical scenes explicitly.',
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
    requiredFields: ['backgroundFill', 'backgroundOpacity', 'children'],
  );
  if (json['artboardSize'] != null)
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
        requiredFields: ['sourceRef'],
      );
      _string(asset['sourceRef'], '$path/sourceRef');
      if (asset['intrinsicSize'] != null) {
        _size(asset['intrinsicSize'], '$path/intrinsicSize');
      }
    }
  }
  final children = _list(json['children'], '/children');
  for (var index = 0; index < children.length; index++) {
    _node(children[index], '/children/$index');
  }
}

void _node(Object? raw, String path) {
  final node = _object(raw, path);
  _keys(
    node,
    {
      'runtimeType',
      'id',
      'name',
      'hidden',
      'xf',
      if (node['runtimeType'] == 'group') ...[
        'behavior',
        'children',
      ] else ...[
        'data',
        'role',
      ],
    },
    path,
    requiredFields: ['runtimeType', 'id'],
  );
  _enum(node['runtimeType'], {
    'path',
    'text',
    'icon',
    'image',
    'group',
  }, '$path/runtimeType');
  _string(node['id'], '$path/id');
  if (node['name'] != null) _string(node['name'], '$path/name');
  if (node['hidden'] != null) _bool(node['hidden'], '$path/hidden');
  if (node['role'] != null) _string(node['role'], '$path/role');
  if (node['xf'] != null) _transform(node['xf'], '$path/xf');
  if (node['runtimeType'] == 'group') {
    _required(node, 'children', path);
    final children = _list(node['children'], '$path/children');
    for (var index = 0; index < children.length; index++) {
      _node(children[index], '$path/children/$index');
    }
    if (node['behavior'] != null) {
      final behavior = _object(node['behavior'], '$path/behavior');
      _keys(
        behavior,
        {'type', 'version', 'data'},
        '$path/behavior',
        requiredFields: ['type', 'version', 'data'],
      );
      _string(behavior['type'], '$path/behavior/type');
      _integer(behavior['version'], '$path/behavior/version');
      // Behavior payloads remain opaque; runtime validation checks JSON values.
      _object(behavior['data'], '$path/behavior/data');
    }
    return;
  }

  _required(node, 'data', path);
  final dataPath = '$path/data';
  final data = _object(node['data'], dataPath);
  switch (node['runtimeType']) {
    case 'path':
      _keys(
        data,
        {'source', 'fillRule', 'appearance'},
        dataPath,
        requiredFields: ['source', 'appearance'],
      );
      _source(data['source'], '$dataPath/source');
      if (data['fillRule'] != null) {
        _enum(data['fillRule'], {'nonZero', 'evenOdd'}, '$dataPath/fillRule');
      }
      _appearance(data['appearance'], '$dataPath/appearance');
    case 'text':
      _keys(
        data,
        {
          'text',
          'fontFamily',
          'fontWeight',
          'fontSize',
          'letterSpacing',
          'appearance',
        },
        dataPath,
        requiredFields: [
          'text',
          'fontFamily',
          'fontWeight',
          'fontSize',
          'appearance',
        ],
      );
      _string(data['text'], '$dataPath/text');
      _string(data['fontFamily'], '$dataPath/fontFamily');
      _integer(data['fontWeight'], '$dataPath/fontWeight');
      _number(data['fontSize'], '$dataPath/fontSize');
      if (data['letterSpacing'] != null)
        _number(data['letterSpacing'], '$dataPath/letterSpacing');
      _appearance(data['appearance'], '$dataPath/appearance');
    case 'icon':
      _keys(
        data,
        {'iconRef', 'sizePx', 'appearance'},
        dataPath,
        requiredFields: ['iconRef', 'appearance'],
      );
      _string(data['iconRef'], '$dataPath/iconRef');
      if (data['sizePx'] != null) _number(data['sizePx'], '$dataPath/sizePx');
      _appearance(data['appearance'], '$dataPath/appearance');
    case 'image':
      _keys(
        data,
        {'assetId', 'size', 'fit', 'align'},
        dataPath,
        requiredFields: ['size'],
      );
      if (data['assetId'] != null)
        _string(data['assetId'], '$dataPath/assetId');
      _size(data['size'], '$dataPath/size');
      if (data['fit'] != null) {
        _enum(data['fit'], {'contain', 'cover', 'fill'}, '$dataPath/fit');
      }
      if (data['align'] != null) _point(data['align'], '$dataPath/align');
  }
}

void _transform(Object? raw, String path) {
  final value = _object(raw, path);
  _keys(value, {
    'position',
    'rotationRad',
    'scale',
    'origin',
    'customPivotPx',
  }, path);
  if (value['position'] != null) _point(value['position'], '$path/position');
  if (value['rotationRad'] != null)
    _number(value['rotationRad'], '$path/rotationRad');
  if (value['scale'] != null) _point(value['scale'], '$path/scale');
  if (value['origin'] != null)
    _enum(value['origin'], {'center', 'custom'}, '$path/origin');
  if (value['customPivotPx'] != null)
    _point(value['customPivotPx'], '$path/customPivotPx');
}

void _appearance(Object? raw, String path) {
  final value = _object(raw, path);
  _keys(
    value,
    {'foreground', 'stroke', 'underlays'},
    path,
    requiredFields: ['foreground', 'underlays'],
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
  // The strict command decoder owns the complete commands source shape.
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
