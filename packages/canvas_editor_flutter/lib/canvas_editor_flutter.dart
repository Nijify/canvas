// Path: oss_packages/canvas_editor_flutter/lib/canvas_editor_flutter.dart
// canvas_editor_flutter – Turnkey scene editor API.
//
// Use this entrypoint to embed CanvasSceneEditor with the package's standard
// viewport, selection, layers, inspector, history, and editing experience.
//
// For composable editor surfaces, custom document adapters, extensions, shell
// configuration, inspector content, actions, or interaction policies, import:
// package:canvas_editor_flutter/extensions.dart
//
// For curated asset-library integration, import:
// package:canvas_editor_flutter/asset_library.dart
//
// For user-image acquisition, import:
// package:canvas_editor_flutter/image_import.dart

library;

export 'src/canvas_scene_editor.dart' show CanvasSceneEditor;
export 'src/editor_host_capabilities.dart';
export 'src/canvas_runtime_resources.dart'
    show
        FontPickerItem,
        IconCatalogItem,
        IconCatalogPort,
        CanvasRuntimeResources;
