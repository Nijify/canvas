// Path: packages/canvas_core/lib/src/serialization/serializers.dart

import 'package:canvas_core/src/runtime/model/scene_document.dart';
import 'package:canvas_core/src/runtime/validation/scene_document_validation.dart';
import 'package:canvas_core/src/serialization/scene_format.dart';
import 'package:canvas_core/src/serialization/formats/scene_v3.dart'
    show validateSceneV3Json;

// Supported annotations for host-owned geometry models.
export 'package:canvas_core/src/serialization/converters.dart'
    show
        Vec2Converter,
        NullableVec2Converter,
        Size2DConverter,
        NullableSize2DConverter;
export 'package:canvas_core/src/serialization/scene_format.dart'
    show currentCanvasSceneFormatVersion;

/// Decodes current persisted JSON: strict wire checks, decoding, then integrity.
///
/// Upgrade historical JSON explicitly first. Malformed wire data throws
/// [FormatException]; invalid runtime values throw [ArgumentError]. Error text
/// is diagnostic context, not a stable code, path, or ordering contract.
CanvasSceneDocument decodeCanvasScene(Map<String, Object?> json) {
  validateSceneV3Json(json);
  final payload = Map<String, dynamic>.from(json)..remove('sceneFormatVersion');
  final scene = CanvasSceneDocument.fromJson(payload);
  requireCanvasSceneIntegrity(scene);
  return scene;
}

/// Checks runtime integrity before recursive encoding to the current format.
///
/// The guard checks cycles, JSON payloads, and node discriminator consistency.
/// Package serializers own canonical wire structure; it is not scanned again.
Map<String, Object?> encodeCanvasScene(CanvasSceneDocument scene) {
  requireCanvasSceneIntegrity(scene);
  return Map<String, Object?>.from(scene.toJson())
    ..['sceneFormatVersion'] = currentCanvasSceneFormatVersion;
}
