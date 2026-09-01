// Path: lib/src/editor_host_capabilities.dart
//
// Common host ports for the generic editor surface.
// Host apps provide concrete implementations for persistence and output.

import 'package:canvas_core/canvas_core_runtime.dart' show CanvasSceneDocument;
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart'
    show CanvasPngSpec;

/// Host-owned final PNG operation.
///
/// The editor supplies one adapter-resolved canonical scene. It has not been
/// passed through a ScenePreparer.
///
/// Implementations own any host-specific output validation and delegate final
/// rendering to an authoritative PNG renderer.
abstract interface class PngExportPort {
  Future<String> sharePng({
    required CanvasSceneDocument scene,
    required CanvasPngSpec spec,
    required String filename,
    String? text,
  });

  Future<String> savePng({
    required CanvasSceneDocument scene,
    required CanvasPngSpec spec,
    required String filename,
  });
}

class PngExportCapability {
  const PngExportCapability({
    required this.port,
    this.canShare = true,
    this.canSave = true,
  });

  final PngExportPort port;
  final bool canShare;
  final bool canSave;
}

// ------------------------------------------------------------
// JSON export
// ------------------------------------------------------------

abstract class JsonOutputPort {
  const JsonOutputPort();

  Future<String> copyJson({required String json});

  Future<String> saveJson({required String json, required String filename});
}

class JsonExportCapability {
  const JsonExportCapability({
    required this.output,
    this.canCopy = true,
    this.canSave = true,
    this.defaultFilename = 'canvas_scene.json',
    this.pretty = true,
  });

  final JsonOutputPort output;
  final bool canCopy;
  final bool canSave;
  final String defaultFilename;
  final bool pretty;
}
