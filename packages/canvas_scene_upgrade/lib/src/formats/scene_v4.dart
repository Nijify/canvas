import 'legacy_scene_wire.dart';

void validateSceneV4Json(Map<String, Object?> json) =>
    validateLegacySceneWire(json, version: 4);
