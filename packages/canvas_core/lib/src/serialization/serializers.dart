// Path: lib/src/serialization/serializers.dart
import 'package:canvas_core/src/runtime/model/scene_document.dart';

export 'package:canvas_core/src/serialization/converters.dart';
export 'package:canvas_core/src/serialization/path_converters.dart';

/// Decodes persisted or externally supplied scene JSON.
CanvasSceneDocument decodeCanvasScene(Map<String, Object?> json) =>
    CanvasSceneDocument.fromJson(Map<String, dynamic>.from(json));

/// Encodes a scene for persistence or external interchange.
Map<String, Object?> encodeCanvasScene(CanvasSceneDocument scene) =>
    Map<String, Object?>.from(scene.toJson());
