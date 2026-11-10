import 'legacy_scene_wire.dart';

void validateSceneV5Json(Map<String, Object?> json) => validateLegacySceneWire(
  json,
  version: 5,
  validateAffine: (raw, path) {
    if (raw is! List ||
        raw.length != 6 ||
        raw.any((value) => value is! num || !value.toDouble().isFinite)) {
      throw FormatException(
        '$path must contain six finite affine coefficients.',
      );
    }
  },
);
