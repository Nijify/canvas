import 'dart:math' as math;

import 'package:canvas_core/src/serialization/formats/scene_v1.dart';
import 'package:canvas_core/src/serialization/formats/scene_v2.dart';

/// Converts a valid v1 persisted scene to explicit v2 gradient semantics.
///
/// V1 resolved every gradient against the artboard dimensions, including fills
/// painted by local node renderers. This conversion writes those exact line
/// endpoints into every migrated gradient so the v2 Flutter renderer preserves
/// the prior appearance.
Map<String, Object?> convertCanvasSceneV1ToV2(Map<String, Object?> v1) {
  validateSceneV1Json(v1);

  // V1 decoding defaulted omitted/null artboardSize to 740 x 360. Preserve
  // that historical behavior so every previously readable v1 document upgrades.
  late final double width;
  late final double height;
  if (v1['artboardSize'] == null) {
    width = 740.0;
    height = 360.0;
  } else {
    final artboard = _object(v1['artboardSize'], 'artboardSize');
    width = _finiteNumber(artboard['w'], 'artboardSize.w');
    height = _finiteNumber(artboard['h'], 'artboardSize.h');
  }
  if (width <= 0 || height <= 0) {
    throw const FormatException(
      'artboardSize.w and artboardSize.h must be greater than zero',
    );
  }

  final result = Map<String, Object?>.from(v1);
  result['sceneFormatVersion'] = canvasSceneFormatV2;
  result['backgroundFill'] = _convertFill(
    v1['backgroundFill'],
    path: 'backgroundFill',
    artboardWidth: width,
    artboardHeight: height,
  );

  final children = v1['children'];
  if (children is! List) {
    throw const FormatException('children must be a list');
  }
  result['children'] = [
    for (var index = 0; index < children.length; index++)
      _convertNode(
        children[index],
        path: 'children[$index]',
        artboardWidth: width,
        artboardHeight: height,
      ),
  ];

  return result;
}

Map<String, Object?> _convertNode(
  Object? raw, {
  required String path,
  required double artboardWidth,
  required double artboardHeight,
}) {
  final node = _object(raw, path);
  final result = Map<String, Object?>.from(node);
  final kind = node['runtimeType'];

  if (kind == 'group') {
    final children = node['children'];
    if (children is! List) {
      throw FormatException('$path.children must be a list');
    }
    result['children'] = [
      for (var index = 0; index < children.length; index++)
        _convertNode(
          children[index],
          path: '$path.children[$index]',
          artboardWidth: artboardWidth,
          artboardHeight: artboardHeight,
        ),
    ];
    return result;
  }

  final data = _object(node['data'], '$path.data');
  final convertedData = Map<String, Object?>.from(data);

  if (kind == 'text' || kind == 'icon') {
    final appearance = _object(data['appearance'], '$path.data.appearance');
    final convertedAppearance = Map<String, Object?>.from(appearance);
    convertedAppearance['foreground'] = _convertFill(
      appearance['foreground'],
      path: '$path.data.appearance.foreground',
      artboardWidth: artboardWidth,
      artboardHeight: artboardHeight,
    );
    convertedData['appearance'] = convertedAppearance;
    result['data'] = convertedData;
    return result;
  }

  if (kind == 'path' && data['fill'] != null) {
    convertedData['fill'] = _convertFill(
      data['fill'],
      path: '$path.data.fill',
      artboardWidth: artboardWidth,
      artboardHeight: artboardHeight,
    );
    result['data'] = convertedData;
  }

  return result;
}

Map<String, Object?> _convertFill(
  Object? raw, {
  required String path,
  required double artboardWidth,
  required double artboardHeight,
}) {
  final fill = _object(raw, path);

  switch (fill['type']) {
    case 'none':
      return const <String, Object?>{'type': 'none'};

    case 'solid':
      return <String, Object?>{
        'type': 'solid',
        'color': _color(fill['color'], '$path.color'),
      };

    case 'gradient':
      final gradient = _object(fill['grad'], '$path.grad');
      final color1 = _color(gradient['color1'], '$path.grad.color1');
      final color2 = _color(gradient['color2'], '$path.grad.color2');
      final angle = _finiteNumber(gradient['angle'], '$path.grad.angle');
      final width = _finiteNumber(gradient['width'], '$path.grad.width');

      final theta = angle * math.pi / 180.0;
      final directionX = math.cos(theta);
      final directionY = math.sin(theta);
      final extent = math.max(artboardWidth, artboardHeight);
      final centerX = artboardWidth / 2.0;
      final centerY = artboardHeight / 2.0;
      final normalizedWidth = width.clamp(0.0, 50.0).toDouble() / 100.0;

      return <String, Object?>{
        'type': 'gradient',
        'grad': <String, Object?>{
          'start': <String, double>{
            'x': centerX - (directionX * extent),
            'y': centerY - (directionY * extent),
          },
          'end': <String, double>{
            'x': centerX + (directionX * extent),
            'y': centerY + (directionY * extent),
          },
          'stops': <Map<String, Object?>>[
            <String, Object?>{'offset': 0.5 - normalizedWidth, 'color': color1},
            <String, Object?>{'offset': 0.5 + normalizedWidth, 'color': color2},
          ],
        },
      };

    default:
      throw FormatException('$path.type is unsupported: ${fill['type']}');
  }
}

int _color(Object? raw, String path) {
  if (raw is! num) throw FormatException('$path must be a number');
  return raw.toInt();
}

double _finiteNumber(Object? raw, String path) {
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
