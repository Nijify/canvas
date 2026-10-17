// Path: packages/canvas_core/lib/src/serialization/serializers.dart

import 'package:canvas_core/src/runtime/model/scene_document.dart';
import 'package:canvas_core/src/runtime/validation/scene_document_validation.dart';
import 'package:canvas_core/src/serialization/scene_format.dart';
import 'package:canvas_core/src/serialization/scene_format_exception.dart';

export 'package:canvas_core/src/serialization/converters.dart';
export 'package:canvas_core/src/serialization/path_converters.dart';
export 'package:canvas_core/src/serialization/scene_format_exception.dart'
    show CanvasSceneFormatException;
export 'package:canvas_core/src/serialization/scene_format.dart'
    show currentCanvasSceneFormatVersion;

/// Decodes current, versioned persisted scene JSON.
///
/// Known legacy JSON must be upgraded explicitly before calling this function.
/// Invalid structure or semantics throw [CanvasSceneFormatException].
///
/// The persistence-format version belongs to the wire format and is removed
/// before constructing the runtime [CanvasSceneDocument].
CanvasSceneDocument decodeCanvasScene(Map<String, Object?> json) {
  validateCurrentCanvasSceneJson(json);

  final payload = Map<String, dynamic>.from(json)..remove('sceneFormatVersion');

  final scene = CanvasSceneDocument.fromJson(payload);
  _validateForPersistence(scene);
  return scene;
}

/// Encodes a runtime scene as current, versioned persisted JSON.
///
/// `sceneFormatVersion` is persistence metadata and is intentionally not part
/// of the runtime [CanvasSceneDocument] model.
/// Invalid runtime data is rejected before serialization.
Map<String, Object?> encodeCanvasScene(CanvasSceneDocument scene) {
  // Validate before recursive serialization, including cyclic runtime graphs.
  _validateForPersistence(scene);
  final json = Map<String, Object?>.from(scene.toJson())
    ..['sceneFormatVersion'] = currentCanvasSceneFormatVersion;
  validateCurrentCanvasSceneJson(json);
  return json;
}

void _validateForPersistence(CanvasSceneDocument scene) {
  final issues = validateCanvasSceneDocument(scene);
  if (issues.isNotEmpty) throw CanvasSceneFormatException(issues.first);
}
