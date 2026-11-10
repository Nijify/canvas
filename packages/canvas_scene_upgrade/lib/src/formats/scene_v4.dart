import 'scene_trs_wire.dart';

void validateSceneV4Json(Map<String, Object?> json) => validateLegacySceneWire(
  json,
  version: 4,
  validateSource: _validateSvgGeometry,
);

void validateSceneV5Json(Map<String, Object?> json) => validateLegacySceneWire(
  json,
  version: 5,
  validateSource: _validateSvgGeometry,
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

void _validateSvgGeometry(Object? raw, String path) {
  if (raw is! Map || raw.keys.any((key) => key is! String)) {
    throw FormatException('$path must be a geometry object.');
  }
}
