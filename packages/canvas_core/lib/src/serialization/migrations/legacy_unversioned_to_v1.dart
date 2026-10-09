// Path: packages/canvas_core/lib/src/serialization/migrations/legacy_unversioned_to_v1.dart

import 'package:canvas_core/src/serialization/formats/scene_v1.dart'
    show canvasSceneFormatV1;

/// Converts an unversioned Canvas scene using the canvas_core 0.10.x
/// persisted wire shape to scene format v1.
///
/// This is intentionally not a generic migration for arbitrary historical
/// unversioned Canvas JSON. Earlier releases used different persisted shapes,
/// including different image representation.
///
/// The caller is responsible for knowing that the input uses the supported
/// 0.10.x wire shape.
///
/// [resolveLegacyIconWasGlyph] is consulted only for an icon with a nonzero
/// legacy shadowOffset. Return true when that icon was rendered as a font
/// glyph, false when it was rendered as a path, or null when its historical
/// rendering mode cannot be determined.
///
/// Does not mutate its input.
Map<String, Object?> convertLegacyUnversionedCanvasSceneToV1(
  Map<String, Object?> legacy, {
  bool? Function(String iconRef)? resolveLegacyIconWasGlyph,
}) {
  if (legacy.containsKey('sceneFormatVersion') ||
      legacy.containsKey('schemaVersion') ||
      legacy.containsKey('base')) {
    throw const FormatException(
      'Expected an unversioned Canvas scene, not a versioned scene or wrapper',
    );
  }

  // The canvas_core 0.10.x generated decoder defaulted omitted/null children
  // to empty.
  final rawChildren = legacy['children'] ?? <Object?>[];
  if (rawChildren is! List) {
    throw const FormatException('children must be a list');
  }

  final result = Map<String, Object?>.from(legacy);
  result['sceneFormatVersion'] = canvasSceneFormatV1;
  result['children'] = <Map<String, Object?>>[
    for (var i = 0; i < rawChildren.length; i++)
      _convertNode(rawChildren[i], 'children[$i]', resolveLegacyIconWasGlyph),
  ];

  return result;
}

Map<String, Object?> _convertNode(
  Object? raw,
  String path,
  bool? Function(String iconRef)? resolveLegacyIconWasGlyph,
) {
  final node = _object(raw, path);
  final kind = node['runtimeType'];
  final id = node['id'];

  if (id is! String) {
    throw FormatException('$path.id must be a string');
  }

  if (node.containsKey('locked') &&
      node['locked'] != null &&
      node['locked'] is! bool) {
    throw FormatException('$path.locked must be a bool');
  }

  final result = Map<String, Object?>.from(node)..remove('locked');

  if (kind == 'group') {
    final rawChildren = node['children'] ?? <Object?>[];
    if (rawChildren is! List) {
      throw FormatException('$path.children must be a list');
    }

    result['children'] = <Map<String, Object?>>[
      for (var i = 0; i < rawChildren.length; i++)
        _convertNode(
          rawChildren[i],
          '$path.children[$i]',
          resolveLegacyIconWasGlyph,
        ),
    ];

    return result;
  }

  if (kind == 'image' || kind == 'path') {
    final data = _object(node['data'], '$path.data');

    if (kind == 'image' && data.containsKey('sourcePath')) {
      throw FormatException(
        '$path.data.sourcePath is not supported by the canvas_core 0.10.x '
        'legacy migration',
      );
    }

    if (data.containsKey('appearance') || data.containsKey('shadowOffset')) {
      throw FormatException('$path.data mixes scene formats');
    }

    return result;
  }

  if (kind != 'text' && kind != 'icon') {
    throw FormatException('$path.runtimeType is unsupported: $kind');
  }

  final data = _object(node['data'], '$path.data');

  if (data.containsKey('appearance')) {
    throw FormatException('$path.data mixes legacy fields with appearance');
  }

  final fill = _legacyFill(data['fill'], '$path.data.fill');
  final shadowOffset = _legacyShadowOffset(
    data['shadowOffset'],
    '$path.data.shadowOffset',
  );

  final underlays = <Map<String, Object?>>[];

  if (shadowOffset != 0) {
    var addShadow = true;

    if (kind == 'icon') {
      final iconRef = data['iconRef'];
      if (iconRef is! String) {
        throw FormatException('$path.data.iconRef must be a string');
      }

      final wasGlyph = resolveLegacyIconWasGlyph?.call(iconRef);

      if (wasGlyph == null) {
        throw FormatException(
          '$path.data.iconRef: cannot migrate a nonzero icon shadow '
          'without resolving whether "$iconRef" was rendered as a glyph '
          'or path icon',
        );
      }

      // The canvas_core 0.10.x renderer used shadowOffset for glyph icons,
      // but not for path-resolved icons.
      addShadow = wasGlyph;
    }

    if (addShadow) {
      underlays.add(<String, Object?>{
        'type': 'shadow',
        'id': 'legacy-shadow-$id',
        'enabled': true,
        'offset': <String, double>{'x': shadowOffset, 'y': shadowOffset},
        'blurSigma': 0.0,
        'color': fill.representativeColor,
      });
    }
  }

  final updatedData = Map<String, Object?>.from(data)
    ..remove('fill')
    ..remove('shadowOffset');

  updatedData['appearance'] = <String, Object?>{
    'foreground': fill.json,
    'underlays': underlays,
  };

  result['data'] = updatedData;
  return result;
}

_LegacyFill _legacyFill(Object? raw, String path) {
  // Defaults match the canvas_core 0.10.x TextData/CanvasIconData decoder.
  if (raw == null) {
    return const _LegacyFill(
      <String, Object?>{'type': 'solid', 'color': 0xFF111111},
      0xFF111111,
    );
  }

  final fill = _object(raw, path);
  switch (fill['type']) {
    case 'solid':
      final color = _legacyColor(fill['color']);
      return _LegacyFill(
        <String, Object?>{'type': 'solid', 'color': color},
        color,
      );
    case 'gradient':
      final gradient = _object(fill['grad'], '$path.grad');
      final color1 = _legacyColor(gradient['color1']);
      final color2 = _legacyColor(gradient['color2']);
      final angle = _legacyNumber(gradient['angle']);
      final width = _legacyNumber(gradient['width']);
      return _LegacyFill(
        <String, Object?>{
          'type': 'gradient',
          'grad': <String, Object?>{
            'color1': color1,
            'color2': color2,
            'angle': angle,
            'width': width,
          },
        },
        color1,
      );
    case 'none':
      throw FormatException('$path cannot be none in a legacy text/icon');
    default:
      throw FormatException('$path has unsupported fill type: ${fill['type']}');
  }
}

int _legacyColor(Object? raw) => raw is num ? raw.toInt() : 0;

double _legacyNumber(Object? raw) => raw is num ? raw.toDouble() : 0.0;

final class _LegacyFill {
  const _LegacyFill(this.json, this.representativeColor);

  final Map<String, Object?> json;
  final int representativeColor;
}

double _legacyShadowOffset(Object? raw, String path) {
  // Default matches the canvas_core 0.10.x generated decoder.
  if (raw == null) return 0.0;

  if (raw is! num || !raw.isFinite) {
    throw FormatException('$path must be a finite number');
  }

  return raw.toDouble();
}

Map<String, Object?> _object(Object? raw, String path) {
  if (raw is! Map || raw.keys.any((key) => key is! String)) {
    throw FormatException('$path must be an object with string keys');
  }

  return Map<String, Object?>.from(raw);
}
