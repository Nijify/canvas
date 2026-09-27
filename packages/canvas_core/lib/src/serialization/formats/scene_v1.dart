// Path: packages/canvas_core/lib/src/serialization/formats/scene_v1.dart

/// First explicitly versioned persisted Canvas scene format.
///
/// The earlier scene format has no embedded version.
const int canvasSceneFormatV1 = 1;

/// Checks v1-specific wire rules. Typed and semantic validation are separate.
void validateSceneV1Json(Map<String, Object?> json) {
  final version = json['sceneFormatVersion'];
  if (version is! int || version != canvasSceneFormatV1) {
    throw FormatException(
      'Expected sceneFormatVersion $canvasSceneFormatV1; got $version',
    );
  }

  if (json.containsKey('schemaVersion') || json.containsKey('base')) {
    throw const FormatException(
      'Expected a Canvas scene, not a tokenized-document wrapper',
    );
  }

  _validateFill(json['backgroundFill'], 'backgroundFill');
  _finiteNumber(json['backgroundOpacity'], 'backgroundOpacity');

  final children = json['children'];
  if (children is! List) {
    throw const FormatException('children must be a list');
  }

  for (var i = 0; i < children.length; i++) {
    _validateNode(children[i], 'children[$i]');
  }
}

void _validateNode(Object? raw, String path) {
  final node = _object(raw, path);
  final kind = node['runtimeType'];

  if (node['id'] is! String) {
    throw FormatException('$path.id must be a string');
  }
  if (node.containsKey('locked')) {
    throw FormatException('$path.locked is not in scene format v1');
  }

  if (kind == 'group') {
    final children = node['children'];
    if (children is! List) {
      throw FormatException('$path.children must be a list');
    }

    for (var i = 0; i < children.length; i++) {
      _validateNode(children[i], '$path.children[$i]');
    }
    return;
  }

  if (kind != 'text' && kind != 'icon' && kind != 'image' && kind != 'path') {
    throw FormatException('$path.runtimeType is unsupported: $kind');
  }

  final data = _object(node['data'], '$path.data');

  if (kind == 'text' || kind == 'icon') {
    if (data.containsKey('fill') || data.containsKey('shadowOffset')) {
      throw FormatException('$path.data contains legacy appearance fields');
    }

    final appearance = _object(data['appearance'], '$path.data.appearance');
    _validateFill(appearance['foreground'], '$path.data.appearance.foreground');

    final underlays = appearance['underlays'];
    if (underlays is! List) {
      throw FormatException('$path.data.appearance.underlays must be a list');
    }

    for (var i = 0; i < underlays.length; i++) {
      _validateUnderlay(underlays[i], '$path.data.appearance.underlays[$i]');
    }
    return;
  }

  if (kind == 'image' && data.containsKey('sourcePath')) {
    throw FormatException('$path.data.sourcePath is not in scene format v1');
  }

  if (data.containsKey('appearance') || data.containsKey('shadowOffset')) {
    throw FormatException('$path.data contains unsupported appearance fields');
  }

  if (kind == 'path' && data['fill'] != null) {
    _validateFill(data['fill'], '$path.data.fill');
  }
}

void _validateUnderlay(Object? raw, String path) {
  final underlay = _object(raw, path);

  if (underlay['type'] != 'shadow') {
    throw FormatException('$path.type is unsupported');
  }
  if (underlay['id'] is! String) {
    throw FormatException('$path.id must be a string');
  }
  if (underlay['enabled'] != null && underlay['enabled'] is! bool) {
    throw FormatException('$path.enabled must be a bool');
  }

  final offset = _object(underlay['offset'], '$path.offset');
  _finiteNumber(offset['x'], '$path.offset.x');
  _finiteNumber(offset['y'], '$path.offset.y');

  if (underlay['blurSigma'] != null) {
    _finiteNumber(underlay['blurSigma'], '$path.blurSigma');
  }
  _finiteNumber(underlay['color'], '$path.color');
}

void _validateFill(Object? raw, String path) {
  final fill = _object(raw, path);

  switch (fill['type']) {
    case 'none':
      return;

    case 'solid':
      _finiteNumber(fill['color'], '$path.color');
      return;

    case 'gradient':
      final grad = _object(fill['grad'], '$path.grad');
      _finiteNumber(grad['color1'], '$path.grad.color1');
      _finiteNumber(grad['color2'], '$path.grad.color2');
      _finiteNumber(grad['angle'], '$path.grad.angle');
      _finiteNumber(grad['width'], '$path.grad.width');
      return;

    default:
      throw FormatException('$path.type is unsupported: ${fill['type']}');
  }
}

void _finiteNumber(Object? raw, String path) {
  if (raw is! num || !raw.isFinite) {
    throw FormatException('$path must be a finite number');
  }
}

Map<String, Object?> _object(Object? raw, String path) {
  if (raw is! Map || raw.keys.any((key) => key is! String)) {
    throw FormatException('$path must be an object with string keys');
  }
  return Map<String, Object?>.from(raw);
}
