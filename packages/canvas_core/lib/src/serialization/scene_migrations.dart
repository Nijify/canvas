// Path: packages/canvas_core/lib/src/serialization/scene_migrations.dart

import 'package:canvas_core/src/runtime/model/scene_document.dart';
import 'package:canvas_core/src/serialization/migrations/legacy_unversioned_to_v1.dart';
import 'package:canvas_core/src/serialization/scene_format.dart';

/// Brings persisted scene JSON to the current scene format.
///
/// Set [legacyUnversioned] only when the caller knows the source is the
/// pre-appearance, unversioned Canvas format. Missing version alone does
/// not identify the source format for arbitrary OSS users.
Map<String, Object?> upgradeCanvasScene(
  Map<String, Object?> json, {
  bool legacyUnversioned = false,
  CanvasLegacyIconKindResolver? resolveLegacyIconKind,
}) {
  final Map<String, Object?> result;

  if (!json.containsKey('sceneFormatVersion')) {
    if (!legacyUnversioned) {
      throw const FormatException(
        'Unversioned scene: identify its legacy source format explicitly',
      );
    }

    result = convertLegacyUnversionedCanvasSceneToV1(
      json,
      resolveLegacyIconKind: resolveLegacyIconKind,
    );
  } else {
    if (legacyUnversioned) {
      throw const FormatException(
        'legacyUnversioned was set for a scene that already has a version',
      );
    }

    // V1 is currently the only versioned format. Add ordered v1 -> v2
    // dispatch here when v2 becomes current.
    result = Map<String, Object?>.from(json);
  }

  validateCurrentCanvasSceneJson(result);

  // Legacy conversion must happen before current typed decoding.
  CanvasSceneDocument.fromJson(Map<String, dynamic>.from(result));

  return result;
}
