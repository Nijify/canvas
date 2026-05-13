// Path: oss_packages/canvas_core/lib/src/serialization/json_vec2.dart

import 'package:canvas_core/src/foundation/core_types.dart';

List<Vec2?> vec2ListNullableFromJson(Object? json) {
  if (json == null) return const [];
  if (json is! List) {
    throw const FormatException('Vec2[] must be a JSON array');
  }

  Vec2? parseOne(Object? e) {
    if (e == null) return null;

    // Object form: {"x": ..., "y": ...}
    if (e is Map) {
      return Vec2.fromJson(e.cast<String, dynamic>());
    }

    // Tuple form: [x, y]
    if (e is List && e.length >= 2) {
      final x = (e[0] as num?)?.toDouble();
      final y = (e[1] as num?)?.toDouble();
      if (x == null || y == null) {
        throw FormatException('Invalid Vec2 tuple: $e');
      }
      return Vec2(x, y);
    }

    throw FormatException('Unsupported Vec2 item: $e');
  }

  return json.map<Vec2?>(parseOne).toList(growable: false);
}

Object? vec2ListNullableToJson(List<Vec2?> value) =>
    value.map((v) => v == null ? null : {'x': v.x, 'y': v.y}).toList();
