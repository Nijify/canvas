import 'package:canvas_core/src/foundation/core_types.dart'
    show LinearGradientSpec;
import 'package:canvas_core/src/runtime/validation/linear_gradient_semantics.dart';

/// Persisted Canvas scene format with explicit linear-gradient semantics.
///
/// Gradients carry local endpoints and ordered stops. Earlier angle/width
/// gradients remain readable only through the explicit v1 -> v2 migration.
const int canvasSceneFormatV2 = 2;

/// Checks v2-specific wire rules. Typed and semantic validation are separate.
void validateSceneV2Json(Map<String, Object?> json) {
  final version = json['sceneFormatVersion'];
  if (version is! int || version != canvasSceneFormatV2) {
    throw FormatException(
      'Expected sceneFormatVersion $canvasSceneFormatV2; got $version',
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

  for (var index = 0; index < children.length; index++) {
    _validateNode(children[index], 'children[$index]');
  }
}

void _validateNode(Object? raw, String path) {
  final node = _object(raw, path);
  final kind = node['runtimeType'];

  if (node['id'] is! String) {
    throw FormatException('$path.id must be a string');
  }
  if (node.containsKey('locked')) {
    throw FormatException('$path.locked is not in scene format v2');
  }

  if (kind == 'group') {
    final children = node['children'];
    if (children is! List) {
      throw FormatException('$path.children must be a list');
    }

    for (var index = 0; index < children.length; index++) {
      _validateNode(children[index], '$path.children[$index]');
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

    for (var index = 0; index < underlays.length; index++) {
      _validateUnderlay(underlays[index], '$path.data.appearance.underlays[$index]');
    }
    return;
  }

  if (kind == 'image' && data.containsKey('sourcePath')) {
    throw FormatException('$path.data.sourcePath is not in scene format v2');
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
      _onlyKeys(fill, const <String>{'type'}, path);
      return;

    case 'solid':
      _onlyKeys(fill, const <String>{'type', 'color'}, path);
      _argbColor(fill['color'], '$path.color');
      return;

    case 'gradient':
      _onlyKeys(fill, const <String>{'type', 'grad'}, path);
      _validateGradient(fill['grad'], '$path.grad');
      return;

    default:
      throw FormatException('$path.type is unsupported: ${fill['type']}');
  }
}

void _validateGradient(Object? raw, String path) {
  // Structure and numeric types belong to the strict typed decoder.
  // Semantic invariants are the same ones used for in-memory documents.
  final LinearGradientSpec gradient;
  try {
    gradient = LinearGradientSpec.fromJson(
      Map<String, dynamic>.from(_object(raw, path)),
    );
  } on FormatException catch (error) {
    throw FormatException('$path: ${error.message}');
  }

  final issues = validateLinearGradientSemantics(gradient);
  if (issues.isNotEmpty) {
    final issue = issues.first;
    final field = issue.path.replaceAll('/', '.');
    throw FormatException('$path$field: ${issue.message}');
  }
}

void _argbColor(Object? raw, String path) {
  if (raw is! int || raw < 0 || raw > 0xFFFFFFFF) {
    throw FormatException('$path must be a 32-bit ARGB integer');
  }
}

double _finiteNumber(Object? raw, String path) {
  if (raw is! num || !raw.isFinite) {
    throw FormatException('$path must be a finite number');
  }
  return raw.toDouble();
}

void _onlyKeys(Map<String, Object?> object, Set<String> allowed, String path) {
  final extras = object.keys.where((key) => !allowed.contains(key)).toList()
    ..sort();
  if (extras.isNotEmpty) {
    throw FormatException('$path contains unsupported key(s): ${extras.join(', ')}');
  }
}

Map<String, Object?> _object(Object? raw, String path) {
  if (raw is! Map || raw.keys.any((key) => key is! String)) {
    throw FormatException('$path must be an object with string keys');
  }
  return Map<String, Object?>.from(raw);
}
