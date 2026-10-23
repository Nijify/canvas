import 'scene_json_wire.dart';

const int canvasSceneFormatV4 = 4;

/// Common scene structure is checked here. The source converter owns exact
/// v4 geometry keys, primitive types, and SVG parsing, so input is parsed once.
void validateSceneV4Json(Map<String, Object?> json) => validateSceneJsonWire(
  json,
  version: canvasSceneFormatV4,
  validateSource: (raw, path) {
    if (raw is! Map || raw.keys.any((key) => key is! String)) {
      throw FormatException('$path must be a geometry object.');
    }
  },
);
