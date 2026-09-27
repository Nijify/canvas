// Path: packages/canvas_core/lib/src/serialization/serializers.dart

import 'package:canvas_core/src/runtime/model/scene_document.dart';
import 'package:canvas_core/src/serialization/scene_format.dart';

export 'package:canvas_core/src/serialization/converters.dart';
export 'package:canvas_core/src/serialization/path_converters.dart';
export 'package:canvas_core/src/serialization/scene_format.dart'
    show currentCanvasSceneFormatVersion;

/// Decodes current, versioned persisted scene JSON.
///
/// Known legacy JSON must be upgraded explicitly before calling this function.
///
/// The persistence-format version belongs to the wire format and is removed
/// before constructing the runtime [CanvasSceneDocument].
CanvasSceneDocument decodeCanvasScene(Map<String, Object?> json) {
  validateCurrentCanvasSceneJson(json);

  final payload = Map<String, dynamic>.from(json)..remove('sceneFormatVersion');

  return CanvasSceneDocument.fromJson(payload);
}

/// Encodes a runtime scene as current, versioned persisted JSON.
///
/// `sceneFormatVersion` is persistence metadata and is intentionally not part
/// of the runtime [CanvasSceneDocument] model.
Map<String, Object?> encodeCanvasScene(CanvasSceneDocument scene) {
  return Map<String, Object?>.from(scene.toJson())
    ..['sceneFormatVersion'] = currentCanvasSceneFormatVersion;
}
