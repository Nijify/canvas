// Path: lib/src/serialization/path_converters.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:canvas_core/src/path/path_source.dart';

/// ---- PathSource ----
/// Use Object? as raw type to avoid brittle generic casts on web.
class PathSourceConverter extends JsonConverter<PathSource, Object?> {
  const PathSourceConverter();

  @override
  PathSource fromJson(Object? json) {
    if (json is Map) {
      return PathSource.fromJson(json.cast<String, Object?>());
    }

    throw const FormatException('PathSource must be an object.');
  }

  @override
  Object? toJson(PathSource object) => object.toJson();
}
