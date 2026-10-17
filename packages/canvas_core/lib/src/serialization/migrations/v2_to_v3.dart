import 'package:canvas_core/src/serialization/formats/scene_v2.dart';
import 'package:canvas_core/src/serialization/formats/scene_v3.dart';
import 'package:canvas_core/src/serialization/json_vec2.dart';
import 'package:canvas_core/src/serialization/serializers.dart';

/// Converts historical path fields into the scene-v3 source/appearance model.
///
/// A non-null source takes precedence over obsolete points, even if those
/// ignored points are malformed. Only the default unconfigured stroke becomes
/// null; nondefault invisible settings and dash arrays remain authored data.
///
/// The result is validated as v3. Input containers are never mutated or shared
/// with the returned scene. Historical validators remain independent of the
/// current runtime model.
Map<String, Object?> convertCanvasSceneV2ToV3(Map<String, Object?> v2) {
  validateSceneV2Json(v2);
  final result = _copy(v2) as Map<String, Object?>;
  result['sceneFormatVersion'] = canvasSceneFormatV3;

  void convertNode(Map<String, Object?> node, String path) {
    if (node['runtimeType'] == 'group') {
      final children = node['children'] as List<Object?>;
      for (var index = 0; index < children.length; index++) {
        convertNode(
          _object(children[index], '$path/children/$index'),
          '$path/children/$index',
        );
      }
      return;
    }
    if (node['runtimeType'] != 'path') return;

    final dataPath = '$path/data';
    final data = _object(node['data'], dataPath);
    final source = data['source'];
    if (source != null) {
      final selected = _object(source, '$dataPath/source');
      if (selected['kind'] == 'polyline') {
        selected['points'] = _points(
          selected['points'],
          '$dataPath/source/points',
        );
      }
      data['source'] = selected;
    } else {
      final points = _points(data['points'], '$dataPath/points');
      data['source'] = points.any((point) => point != null)
          ? <String, Object?>{'kind': 'polyline', 'points': points}
          : <String, Object?>{'kind': 'commands', 'commands': <Object?>[]};
    }

    final stroke = <String, Object?>{
      'color': data['strokeColor'] ?? 0,
      'width': data['strokeWidth'] ?? 4.0,
      'cap': data['strokeCap'] ?? 'butt',
      'join': data['strokeJoin'] ?? 'miter',
      'miterLimit': data['miterLimit'] ?? 4.0,
      'dash': data['dash'] ?? <Object?>[],
    };
    final dash = stroke['dash'];
    final isDefault =
        stroke['color'] is int &&
        stroke['color'] == 0 &&
        stroke['width'] == 4.0 &&
        stroke['cap'] == 'butt' &&
        stroke['join'] == 'miter' &&
        stroke['miterLimit'] == 4.0 &&
        dash is List &&
        dash.isEmpty;
    data['appearance'] = <String, Object?>{
      'foreground': data['fill'] ?? <String, Object?>{'type': 'none'},
      'stroke': isDefault ? null : stroke,
      'underlays': <Object?>[],
    };
    data['fillRule'] ??= 'nonZero';
    for (final name in [
      'points',
      'fill',
      'strokeColor',
      'strokeWidth',
      'strokeCap',
      'strokeJoin',
      'miterLimit',
      'dash',
    ]) {
      data.remove(name);
    }
    node['data'] = data;
  }

  final children = result['children'] as List<Object?>;
  for (var index = 0; index < children.length; index++) {
    convertNode(
      _object(children[index], '/children/$index'),
      '/children/$index',
    );
  }

  decodeCanvasScene(result);
  return result;
}

List<Object?> _points(Object? raw, String path) {
  try {
    // Historical point sources accepted object and tuple coordinates. Write
    // only canonical point objects in v3, keeping null contour separators.
    return [for (final point in vec2ListNullableFromJson(raw)) point?.toJson()];
  } on FormatException catch (error) {
    throw FormatException('$path: ${error.message}');
  } on TypeError {
    throw FormatException('$path contains an invalid legacy point.');
  }
}

Map<String, Object?> _object(Object? raw, String path) {
  if (raw is! Map<String, Object?>) {
    throw FormatException('$path must be an object with string keys.');
  }
  return raw;
}

Object? _copy(Object? value) {
  if (value is Map) {
    if (value.keys.any((key) => key is! String)) {
      throw const FormatException('Scene objects require string keys.');
    }
    return <String, Object?>{
      for (final entry in value.entries)
        (entry.key as String): _copy(entry.value),
    };
  }
  if (value is List) return <Object?>[for (final item in value) _copy(item)];
  return value;
}
