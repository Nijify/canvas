import 'package:canvas_core/canvas_core_runtime.dart' show decodeCanvasScene;

import 'formats/scene_v1.dart';
import 'formats/scene_v2.dart';
import 'formats/scene_v3.dart';
import 'migrations/legacy_unversioned_to_v1.dart';
import 'migrations/v1_to_v2.dart';
import 'migrations/v2_to_v3.dart';
import 'migrations/v3_to_v4.dart';

/// Upgrades supported historical JSON to the current Canvas scene format (v4).
///
/// The input is never mutated. Intermediate steps use historical wire checks;
/// only the completed upgrade is decoded and integrity-checked by current core.
/// This does not resolve resources or guarantee identical historical rendering.
/// Malformed wire data throws [FormatException]; final runtime integrity
/// failures throw [ArgumentError]. Diagnostic error text is not a stable API.
///
/// Set [legacyUnversioned] only when the caller knows the input uses the
/// supported canvas_core 0.10.x wire shape. Missing version metadata alone does
/// not identify it. Other unversioned formats are unsupported.
///
/// [resolveLegacyIconWasGlyph] is needed for a supported unversioned icon with
/// a nonzero shadowOffset: true means a historical font glyph, false means a
/// path, and null means unknown. Ambiguous rendering is rejected.
Map<String, Object?> upgradeCanvasScene(
  Map<String, Object?> json, {
  bool legacyUnversioned = false,
  bool? Function(String iconRef)? resolveLegacyIconWasGlyph,
}) {
  var source = json;
  if (!source.containsKey('sceneFormatVersion')) {
    if (!legacyUnversioned) {
      throw const FormatException(
        'Unversioned Canvas scene: the caller must explicitly identify '
        'a supported legacy source format.',
      );
    }
    source = convertLegacyUnversionedCanvasSceneToV1(
      source,
      resolveLegacyIconWasGlyph: resolveLegacyIconWasGlyph,
    );
  } else if (legacyUnversioned) {
    throw const FormatException(
      'legacyUnversioned was set for a scene that already has '
      'sceneFormatVersion.',
    );
  }

  final version = source['sceneFormatVersion'];
  if (version is! int) {
    throw const FormatException('sceneFormatVersion must be an integer.');
  }

  final result = switch (version) {
    canvasSceneFormatV1 => convertCanvasSceneV3ToV4(
      convertCanvasSceneV2ToV3(convertCanvasSceneV1ToV2(source)),
    ),
    canvasSceneFormatV2 => convertCanvasSceneV3ToV4(
      convertCanvasSceneV2ToV3(source),
    ),
    canvasSceneFormatV3 => convertCanvasSceneV3ToV4(source),
    4 => Map<String, Object?>.from(source),
    _ => throw FormatException(
      'Unsupported Canvas sceneFormatVersion: $version',
    ),
  };

  decodeCanvasScene(result);
  return result;
}
