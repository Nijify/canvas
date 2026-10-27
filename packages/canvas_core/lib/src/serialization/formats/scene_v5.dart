import 'scene_json_wire.dart';

const int canvasSceneFormatV5 = 5;

/// Common scene structure is checked here. The source converter owns exact
/// v5 geometry keys, primitive types, and SVG parsing, so input is parsed once.
void validateSceneV5Json(Map<String, Object?> json) => validateSceneJsonWire(
  json,
  version: canvasSceneFormatV5,
  validateSource: (raw, path) {
    if (raw is! Map || raw.keys.any((key) => key is! String)) {
      throw FormatException('$path must be a geometry object.');
    }
  },
);
