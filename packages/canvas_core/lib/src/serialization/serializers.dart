// Path: packages/canvas_core/lib/src/serialization/serializers.dart

import 'package:canvas_core/src/runtime/model/scene_document.dart';
import 'package:canvas_core/src/runtime/resources/scene_image_assets.dart';
import 'package:canvas_core/src/serialization/scene_format.dart';
import 'package:canvas_core/src/serialization/formats/scene_v7.dart'
    show validateSceneV7Json;

// Supported annotations for host-owned geometry models.
export 'package:canvas_core/src/serialization/converters.dart'
    show
        Vec2Converter,
        NullableVec2Converter,
        Size2DConverter,
        NullableSize2DConverter;
export 'package:canvas_core/src/serialization/scene_format.dart'
    show currentCanvasSceneFormatVersion;

/// Decodes current JSON, validates integrity, and prunes unused image assets.
///
/// Upgrade historical JSON explicitly with the optional `canvas_scene_upgrade`
/// package first. Malformed wire data throws
/// [FormatException]; invalid runtime values throw [ArgumentError]. Error text
/// is diagnostic context, not a stable code, path, or ordering contract.
CanvasSceneDocument decodeCanvasScene(Map<String, Object?> json) {
  validateSceneV7Json(json);
  final payload = Map<String, dynamic>.from(json)..remove('sceneFormatVersion');
  final scene = CanvasSceneDocument.fromJson(payload);
  return pruneUnusedImageAssets(scene);
}

/// Checks runtime integrity before recursive encoding to the current format.
///
/// The guard checks cycles and node discriminator consistency.
/// Unreferenced image assets are omitted without modifying the input scene.
/// Package serializers own canonical wire structure; it is not scanned again.
Map<String, Object?> encodeCanvasScene(CanvasSceneDocument scene) {
  final normalized = pruneUnusedImageAssets(scene);
  return Map<String, Object?>.from(normalized.toJson())
    ..['sceneFormatVersion'] = currentCanvasSceneFormatVersion;
}
