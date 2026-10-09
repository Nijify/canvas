// Path: packages/canvas_core/lib/src/serialization/scene_migrations.dart

import 'package:canvas_core/src/serialization/formats/scene_v1.dart';
import 'package:canvas_core/src/serialization/formats/scene_v2.dart';
import 'package:canvas_core/src/serialization/migrations/legacy_unversioned_to_v1.dart';
import 'package:canvas_core/src/serialization/migrations/v1_to_v2.dart';
import 'package:canvas_core/src/serialization/serializers.dart';

/// Brings persisted scene JSON to the current Canvas scene format.
///
/// Set [legacyUnversioned] only when the caller knows that an unversioned input
/// uses the supported canvas_core 0.10.x persisted wire shape.
///
/// Missing `sceneFormatVersion` alone does not identify an arbitrary historical
/// Canvas scene as this legacy format. Earlier unversioned releases used
/// different persisted shapes.
///
/// [resolveLegacyIconWasGlyph] is needed only when upgrading the supported
/// unversioned format and an icon has a nonzero legacy shadowOffset. Return
/// true when the icon was historically rendered as a font glyph, false when it
/// was rendered as a path, or null when that cannot be determined.
///
/// Versioned scenes are dispatched through their explicit migration steps
/// before the final current-format decode.
Map<String, Object?> upgradeCanvasScene(
  Map<String, Object?> json, {
  bool legacyUnversioned = false,
  bool? Function(String iconRef)? resolveLegacyIconWasGlyph,
}) {
  final Map<String, Object?> result;

  if (!json.containsKey('sceneFormatVersion')) {
    if (!legacyUnversioned) {
      throw const FormatException(
        'Unversioned Canvas scene: the caller must explicitly identify '
        'a supported legacy source format.',
      );
    }

    result = convertCanvasSceneV1ToV2(
      convertLegacyUnversionedCanvasSceneToV1(
        json,
        resolveLegacyIconWasGlyph: resolveLegacyIconWasGlyph,
      ),
    );
  } else {
    if (legacyUnversioned) {
      throw const FormatException(
        'legacyUnversioned was set for a scene that already has '
        'sceneFormatVersion.',
      );
    }

    switch (json['sceneFormatVersion']) {
      case canvasSceneFormatV1:
        result = convertCanvasSceneV1ToV2(json);
      case canvasSceneFormatV2:
        result = Map<String, Object?>.from(json);
      default:
        throw FormatException(
          'Unsupported Canvas sceneFormatVersion: '
          '${json['sceneFormatVersion']}',
        );
    }
  }

  // The canonical persisted-scene read boundary performs current wire-format
  // validation and then typed decoding.
  decodeCanvasScene(result);

  return result;
}
