import 'scene_trs_wire.dart';

void validateSceneV4Json(Map<String, Object?> json) => validateLegacySceneWire(
  json, version: 4,
  validateSource: (raw, path) {
    if (raw is! Map || raw.keys.any((key) => key is! String)) {
      throw FormatException('$path must be a geometry object.');
    }
  },
);
