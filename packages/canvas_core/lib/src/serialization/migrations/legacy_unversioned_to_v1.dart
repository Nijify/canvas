// Path: packages/canvas_core/lib/src/serialization/migrations/legacy_unversioned_to_v1.dart

import 'package:canvas_core/src/foundation/paint/canvas_fill.dart';
import 'package:canvas_core/src/serialization/formats/scene_v1.dart'
    show canvasSceneFormatV1;

enum CanvasLegacyIconKind { glyph, path }

typedef CanvasLegacyIconKindResolver =
    CanvasLegacyIconKind? Function(String iconRef);

/// Converts a scene the caller has identified as pre-appearance,
/// unversioned Canvas JSON. Does not mutate its input.
Map<String, Object?> convertLegacyUnversionedCanvasSceneToV1(
  Map<String, Object?> legacy, {
  CanvasLegacyIconKindResolver? resolveLegacyIconKind,
}) {
  if (legacy.containsKey('sceneFormatVersion') ||
      legacy.containsKey('schemaVersion') ||
      legacy.containsKey('base')) {
    throw const FormatException(
      'Expected an unversioned Canvas scene, not a versioned scene or wrapper',
    );
  }

  // The old generated decoder defaulted omitted/null children to empty.
  final rawChildren = legacy['children'] ?? <Object?>[];
  if (rawChildren is! List) {
    throw const FormatException('children must be a list');
  }

  final result = Map<String, Object?>.from(legacy);
  result['sceneFormatVersion'] = canvasSceneFormatV1;
  result['children'] = <Map<String, Object?>>[
    for (var i = 0; i < rawChildren.length; i++)
      _convertNode(rawChildren[i], 'children[$i]', resolveLegacyIconKind),
  ];

  return result;
}

Map<String, Object?> _convertNode(
  Object? raw,
  String path,
  CanvasLegacyIconKindResolver? resolveLegacyIconKind,
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
          resolveLegacyIconKind,
        ),
    ];
    return result;
  }

  if (kind == 'image' || kind == 'path') {
    final data = _object(node['data'], '$path.data');
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

      final iconKind = resolveLegacyIconKind?.call(iconRef);
      if (iconKind == null) {
        throw FormatException(
          '$path.data.iconRef: cannot migrate a nonzero icon shadow '
          'without resolving whether "$iconRef" is a glyph or path icon',
        );
      }

      // The old renderer used shadowOffset for glyph icons, not path icons.
      addShadow = iconKind == CanvasLegacyIconKind.glyph;
    }

    if (addShadow) {
      underlays.add(<String, Object?>{
        'type': 'shadow',
        'id': 'legacy-shadow-$id',
        'enabled': true,
        'offset': <String, double>{'x': shadowOffset, 'y': shadowOffset},
        'blurSigma': 0.0,
        'color': switch (fill) {
          CanvasFillSolid(:final color) => color,
          CanvasFillGradient(:final grad) => grad.color1,
          CanvasFillNone() => throw FormatException(
            '$path.data.fill cannot be none in a legacy text/icon',
          ),
        },
      });
    }
  }

  final updatedData = Map<String, Object?>.from(data)
    ..remove('fill')
    ..remove('shadowOffset');

  updatedData['appearance'] = <String, Object?>{
    'foreground': fill.toJson(),
    'underlays': underlays,
  };
  result['data'] = updatedData;
  return result;
}

CanvasFill _legacyFill(Object? raw, String path) {
  // Default from the old TextData/CanvasIconData generated decoder.
  if (raw == null) {
    return const CanvasFill.solid(0xFF111111);
  }

  final CanvasFill fill;
  try {
    fill = CanvasFill.fromJson(_object(raw, path));
  } on FormatException catch (error) {
    throw FormatException('$path: $error');
  } on TypeError catch (error) {
    throw FormatException('$path: $error');
  }

  if (fill is CanvasFillNone) {
    throw FormatException('$path cannot be none in a legacy text/icon');
  }
  return fill;
}

double _legacyShadowOffset(Object? raw, String path) {
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
