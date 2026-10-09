// Path: packages/canvas_core/lib/src/serialization/scene_format.dart

import 'package:canvas_core/src/serialization/formats/scene_v2.dart';

/// Current persisted Canvas scene format; independent of package version.
const int currentCanvasSceneFormatVersion = canvasSceneFormatV2;

/// Validates the currently supported persisted wire shape.
void validateCurrentCanvasSceneJson(Map<String, Object?> json) {
  validateSceneV2Json(json);
}
