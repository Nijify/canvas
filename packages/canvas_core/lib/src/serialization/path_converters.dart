// Path: oss_packages/canvas_core/lib/src/serialization/path_converters.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:canvas_core/src/path/path_source.dart';

/// ---- PathSource ----
/// Use Object? as raw type to avoid brittle generic casts on web.
class PathSourceConverter extends JsonConverter<PathSource?, Object?> {
  const PathSourceConverter();

  @override
  PathSource? fromJson(Object? json) {
    if (json == null) return null;

    if (json is Map) {
      return PathSource.fromJson(json.cast<String, Object?>());
    }

    throw FormatException('Unsupported PathSource: $json');
  }

  @override
  Object? toJson(PathSource? object) => object?.toJson();
}
