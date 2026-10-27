// Historical object/tuple point parsing used by the v2 -> v3 upgrade.

import 'package:canvas_core/canvas_core_runtime.dart' show Vec2;

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
