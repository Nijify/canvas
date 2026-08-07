// Path: oss_packages/canvas_editor_flutter/lib/src/editor_host_capabilities.dart
//
// Common host ports for the generic editor surface.
// Host apps provide concrete implementations for persistence, media, and output.

import 'package:canvas_core/canvas_core_runtime.dart'
    show CanvasFit, CanvasSceneDocument;

typedef JsonMap = Map<String, Object?>;

/// Export configuration for editor host ports.
class EditorExportSpec {
  const EditorExportSpec({
    required this.widthPx,
    required this.heightPx,
    this.bleedPx = 0,
    this.pixelRatio = 2.0,
    this.transparent = true,
    this.fit = CanvasFit.contain,

    // Optional export mode that trims empty artboard area around rendered content.
    this.cropToContent = false,
    this.contentPaddingPx = 0,
    this.tight = false,
  });

  final int widthPx;
  final int heightPx;
  final int bleedPx;
  final double pixelRatio;
  final bool transparent;
  final CanvasFit fit;

  final bool cropToContent;
  final double contentPaddingPx;
  final bool tight;
}

/// Host-owned final PNG operation.
///
/// The editor supplies both the canonical editable scene and the prepared scene
/// currently used for visual rendering.
///
/// Implementations own the complete final PNG operation, including any host
/// policy checks, runtime resource preparation, rendering, and platform output
/// required to complete it.
///
/// Hosts should use [editableScene] for document-level policy or semantics and
/// [preparedScene] for PNG rendering.
abstract interface class PngExportPort {
  Future<String> sharePng({
    required CanvasSceneDocument editableScene,
    required CanvasSceneDocument preparedScene,
    required EditorExportSpec spec,
    required String filename,
    String? text,
  });

  Future<String> savePng({
    required CanvasSceneDocument editableScene,
    required CanvasSceneDocument preparedScene,
    required EditorExportSpec spec,
    required String filename,
  });
}

class PngExportAvailability {
  const PngExportAvailability({required this.canShare, required this.canSave});

  static const none = PngExportAvailability(canShare: false, canSave: false);

  static const all = PngExportAvailability(canShare: true, canSave: true);

  final bool canShare;
  final bool canSave;

  bool get hasAny => canShare || canSave;
}

class PngExportCapability {
  const PngExportCapability({
    required this.port,
    this.availability = PngExportAvailability.all,
  });

  final PngExportPort port;
  final PngExportAvailability availability;

  bool get canShare => availability.canShare;
  bool get canSave => availability.canSave;
}

// ------------------------------------------------------------
// JSON export
// ------------------------------------------------------------

abstract class JsonOutputPort {
  const JsonOutputPort();

  Future<String> copyJson({required String json});

  Future<String> saveJson({required String json, required String filename});
}

class JsonExportAvailability {
  const JsonExportAvailability({required this.canCopy, required this.canSave});

  static const none = JsonExportAvailability(canCopy: false, canSave: false);

  static const all = JsonExportAvailability(canCopy: true, canSave: true);

  final bool canCopy;
  final bool canSave;

  bool get hasAny => canCopy || canSave;
}

class JsonExportCapability {
  const JsonExportCapability({
    required this.output,
    this.availability = JsonExportAvailability.all,
    this.defaultFilename = 'canvas_scene.json',
    this.pretty = true,
  });

  final JsonOutputPort output;
  final JsonExportAvailability availability;
  final String defaultFilename;
  final bool pretty;

  bool get canCopy => availability.canCopy;
  bool get canSave => availability.canSave;
}
