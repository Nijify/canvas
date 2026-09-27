// Path: packages/canvas_core/lib/src/serialization/serializers.dart

import 'package:canvas_core/src/runtime/model/scene_document.dart';
import 'package:canvas_core/src/serialization/scene_format.dart';

export 'package:canvas_core/src/serialization/converters.dart';
export 'package:canvas_core/src/serialization/path_converters.dart';
export 'package:canvas_core/src/serialization/scene_format.dart'
    show currentCanvasSceneFormatVersion;
export 'package:canvas_core/src/serialization/migrations/legacy_unversioned_to_v1.dart'
    show CanvasLegacyIconKind, CanvasLegacyIconKindResolver;
export 'package:canvas_core/src/serialization/scene_migrations.dart'
    show upgradeCanvasScene;

/// Decodes current, versioned persisted scene JSON.
/// Upgrade known older JSON before calling this function.
CanvasSceneDocument decodeCanvasScene(Map<String, Object?> json) {
  validateCurrentCanvasSceneJson(json);
  return CanvasSceneDocument.fromJson(Map<String, dynamic>.from(json));
}

/// Encodes a runtime scene as current, versioned persisted JSON.
Map<String, Object?> encodeCanvasScene(CanvasSceneDocument scene) {
  return Map<String, Object?>.from(scene.toJson())
    ..['sceneFormatVersion'] = currentCanvasSceneFormatVersion;
}
