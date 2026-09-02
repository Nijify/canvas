# canvas_editor_flutter

`canvas_editor_flutter` is a complete Flutter scene editor for `canvas_core` documents. It provides a turnkey editing experience and composable APIs for custom document models and product experiences, including viewport controls, selection, layers, inspector UI, history, runtime resources, asset libraries, image import, image tools, and export capabilities.

## Features

- `CanvasSceneEditor` for a complete turnkey `CanvasSceneDocument` editor.
- `CanvasEditorSurface` for composing an editor around custom documents, extensions, shell configuration, and interaction behavior.
- Selection, movement, viewport behavior, inspector UI, layers, history, and editor actions.
- Composable seams for scene preparation, field codecs, live surface configuration, actions, providers, and custom inspector rows.
- `CanvasRuntimeResources` for font loading, font-picker metadata, icon catalogs, and logical image-source resolution.
- Asset-library, user-image acquisition, and host-owned image-tool capabilities.
- Host-owned PNG and JSON export capabilities.

## Installation

```bash
flutter pub add canvas_editor_flutter canvas_core canvas_renderer_flutter
```

## Imports

Turnkey editor:

```dart
import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/canvas_editor_flutter.dart';
```

Composable editor surfaces and extensions:

```dart
import 'package:canvas_editor_flutter/extensions.dart';
```

Optional capabilities:

```dart
import 'package:canvas_editor_flutter/asset_library.dart';
import 'package:canvas_editor_flutter/image_import.dart';
import 'package:canvas_editor_flutter/image_tools.dart';
```

Do not import files under `package:canvas_editor_flutter/src/`.

The editor does not re-export renderer-owned APIs. Hosts that construct `FlutterFontLoader`, `CanvasPngSpec`, or `FlutterCanvasPngRenderer` should import `canvas_renderer_flutter` explicitly.

## Runtime resources

`CanvasRuntimeResources` is a passive capability bundle:

```dart
final resources = CanvasRuntimeResources(
  fonts: appFontLoader,
  pickerFonts: const [
    FontPickerItem(
      family: 'Inter',
      label: 'Inter',
    ),
  ],
  icons: appIcons,
  images: appImageResolver,
);
```

Its responsibilities are intentionally separated:

- `fonts` is a renderer-owned `FlutterFontLoader` that makes logical families available to Flutter.
- `pickerFonts` is editor presentation metadata only.
- `icons` resolves logical icon refs and supplies picker/catalog metadata.
- `images` is the core-owned `CanvasImageAssetResolver` for logical canvas image `sourceRef` values.

The editor uses these capabilities for interactive resource loading. It does not own application persistence, signed-URL refresh, server media IDs, or remote font/media storage.

## Basic usage

```dart
CanvasSceneEditor(
  initialScene: scene,
  resources: resources,
  onSceneChanged: (updatedScene) {
    persistScene(updatedScene);
  },
)
```

To add user-image acquisition and background removal:

```dart
CanvasSceneEditor(
  initialScene: scene,
  resources: resources,
  extensions: [
    imageImportExtension(
      imageImport: appImageImportPort,
    ),
    backgroundRemovalExtension(
      port: appBackgroundRemovalPort,
    ),
  ],
)
```

`imageImportExtension(...)` adds image acquisition, durable logical-source import, image replacement, and Add → Image behavior. Initial image sizing uses stable intrinsic metadata when available and keeps the built-in fallback when metadata is missing or slow.

`backgroundRemovalExtension(...)` adds an Image-tools inspector section. Canvas validates the selected target and field state before and after the asynchronous host operation, then commits an accepted replacement through `CanvasFields.imageSource`. The host owns image access, processing, persistence, and cleanup of unreferenced outputs.

A curated asset library is supplied through `canvasAssetLibraryExtension(...)`. The application provides the catalog and selection presentation; the extension inserts the selected asset, preserves its aspect ratio, records history, and selects the new node.

## Editor session lifecycle

`CanvasSceneEditor` and `CanvasEditorSurface` create uncontrolled editor sessions.

Initial document/source configuration, runtime resources, and extension composition are captured when the session is created. Rebuilding with the same key preserves the active edited document, history, selection, renderer caches, and resource graph.

Use a new key to intentionally switch documents, discard edits, or replace session-level resources/extensions:

```dart
CanvasSceneEditor(
  key: ValueKey('design:$designId:$reloadRevision'),
  initialScene: scene,
  resources: resources,
  onSceneChanged: saveDraft,
)
```

## Interactive rendering vs final output

Interactive rendering intentionally uses a prepared scene:

```text
current source document
  -> EditorDocumentAdapter.resolve()
  -> optional ScenePreparer
  -> CanvasRenderPipeline.build()
  -> RenderSnapshot
```

The canonical/base scene remains authoritative for editing, history, persistence, and scene JSON export.

Final PNG output uses a different boundary:

```text
current source document
  -> EditorDocumentAdapter.resolve()
  -> EditorController.resolveSceneForOutput()
  -> PngExportPort
  -> authoritative CanvasPngRenderer
  -> optional ScenePreparer exactly once inside final rendering
```

`EditorController.resolveSceneForOutput()` returns the current adapter-resolved runtime scene **without** invoking `ScenePreparer`. This prevents interactive prepared state from becoming the authoritative export input or being prepared twice.

## Export capabilities

PNG and JSON actions are opt-in:

```dart
CanvasSceneEditor(
  initialScene: scene,
  resources: resources,
  pngExport: PngExportCapability(
    port: appPngExport,
    canShare: true,
    canSave: false,
  ),
  jsonExport: JsonExportCapability(
    output: appJsonOutput,
    canCopy: true,
    canSave: false,
  ),
)
```

`PngExportPort` receives one adapter-resolved, unprepared `CanvasSceneDocument`, a renderer-owned `CanvasPngSpec`, and output metadata. A typical host implementation delegates to `FlutterCanvasPngRenderer` from `canvas_renderer_flutter`.

The editor deliberately does not pass both editable and prepared scenes to PNG hosts, and it does not re-export `CanvasPngSpec` or renderer implementations.

Scene JSON export remains based on the canonical editable/base scene.

## Composition model

Use `CanvasEditorSurface<TSourceDocument>` with ordered `EditorExtension<TSourceDocument>` values when operating on a custom source model.

`CanvasEditorSurface` owns session-level inputs including:

- `initialDocument`
- `adapter`
- `initialResolveContext`
- `resources`
- ordered `extensions`

An extension may contribute `scenePreparer`, field codecs, surface features, actions, providers, and inspector content. Extension composition permits at most one non-null `scenePreparer`; preparation order must not depend on extension ordering.

`EditorRuntime` itself remains unaware of extension composition. It receives the selected preparer and field codecs as plain constructor inputs.

## Architecture

See [doc/architecture.md](doc/architecture.md) for package layering, mutation flow, runtime-resource ownership, and the interactive/final-output boundary.

## Package boundaries

- `canvas_editor_flutter` owns the reusable Flutter editor experience and editor-specific presentation contracts.
- `canvas_core` owns the document model, geometry, scene computation, logical image-resource contracts, and renderer-agnostic paint operations.
- `canvas_renderer_flutter` owns Flutter drawing, text/font resource implementations, decoded image ownership, and canonical PNG rendering.
- Applications own persistence, authentication, analytics, networking, permissions, image processing, media/font lifecycle, and product-specific workflows.

## Localization

The built-in editor interface currently ships with English UI text. Applications may provide custom surrounding UI and editor chrome; built-in inspector, layers, toolbar, dialog, and tooltip strings are not currently configurable.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).

Copyright 2026 Nijify.
