# canvas_editor_flutter

`canvas_editor_flutter` is a complete Flutter scene editor for `canvas_core`
documents. It provides a turnkey editing experience and composable APIs for
custom document models and product experiences, including viewport controls,
selection, layers, inspector UI, history, runtime resources, asset libraries,
image import, image tools, and export capabilities.

## Features

* `CanvasSceneEditor` for a complete turnkey `CanvasSceneDocument` editor.
* `CanvasEditorSurface` for composing an editor around custom documents,
  extensions, shell configuration, and interaction behavior.
* Selection, movement, viewport behavior, inspector UI, layers, history, and
  editor actions.
* Composable seams for scene preparation, field codecs, live surface
  configuration, actions, providers, and custom inspector rows.
* `CanvasRuntimeResources` for font loading, icon catalogs, and media/source
  resolution.
* Asset-library, user-image acquisition, and host-owned image-tool capabilities.
* PNG and JSON export capabilities.

## Installation

Add the editor and its runtime packages to your Flutter app:

```bash
flutter pub add canvas_editor_flutter canvas_core canvas_renderer_flutter
```

## Imports

For the turnkey scene editor:

```dart
import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/canvas_editor_flutter.dart';
```

For composable editor surfaces, custom document adapters, extensions, shell
configuration, inspector content, actions, or interaction policies:

```dart
import 'package:canvas_editor_flutter/extensions.dart';
```

For curated asset-library integration:

```dart
import 'package:canvas_editor_flutter/asset_library.dart';
```

For Gallery, Camera, or other user-image acquisition flows:

```dart
import 'package:canvas_editor_flutter/image_import.dart';
```

For host-owned destructive image transformations such as background removal:

```dart
import 'package:canvas_editor_flutter/image_tools.dart';
```

The capability entrypoints are additive. The turnkey editor remains a complete
scene editor without them; import a capability only when the application needs
that workflow.

Do not import files under `package:canvas_editor_flutter/src/`.

## Basic usage

Provide an initial scene plus runtime resources implemented by your app:

```dart
final resources = CanvasRuntimeResources(
  fonts: appFonts,
  icons: appIcons,
  media: appMediaResolver,
);

CanvasSceneEditor(
  initialScene: scene,
  resources: resources,
  onSceneChanged: (updatedScene) {
    persistScene(updatedScene);
  },
)
```

`CanvasRuntimeResources` connect the editor to fonts, icons, and media sources
used by the document.

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

`imageImportExtension(...)` adds image acquisition, durable source import,
image replacement, and Add → Image behavior.

`backgroundRemovalExtension(...)` adds an Image-tools inspector section. Canvas
validates the selected target, field editability, and canonical/effective source
state before and after the asynchronous operation, then commits the returned
replacement through `CanvasFields.imageSource`. The host owns image access,
processing, persistence, and creation of the new durable source reference.

A successful `BackgroundRemovalPort` result may become stale before the editor
can adopt it. Hosts must tolerate temporarily unreferenced outputs; cleanup and
resource lifecycle remain host responsibilities.

A curated asset library is supplied through `canvasAssetLibraryExtension(...)`.
The application provides the catalog and selection presentation; the extension
inserts the selected asset, preserves its aspect ratio, records history, and
selects the new node.

## Editor session lifecycle

`CanvasSceneEditor` is an uncontrolled editor-session widget.

The initial scene, runtime resources, export capabilities, and extensions are
captured when the editor session is created.

Rebuilding with the same key preserves the active edited document, history,
selection, renderer caches, and resource set. It does not replace the active
document from `initialScene`.

To intentionally switch documents, discard edits, reload a chosen version, or
use a different resource or capability set, rebuild with a different key.

```dart
CanvasSceneEditor(
  key: ValueKey('design:$designId:$reloadRevision'),
  initialScene: scene,
  resources: resources,
  onSceneChanged: saveDraft,
)
```

Change `reloadRevision` only after an explicit decision to switch documents,
discard edits, or reload a chosen version. Do not change it for normal parent
rebuilds, autosave state updates, or ordinary UI changes.

## Export capabilities

PNG and JSON export actions are opt-in capabilities. Configure action
availability directly on each capability:

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

Scene JSON export uses the canonical editable scene. PNG export uses the
current prepared render scene and passes it to the application as a typed
`CanvasSceneDocument`, commonly through a `PngExportCapability` backed by
`CanvasDocumentExporter` from `canvas_renderer_flutter`. The PNG path does not
serialize and decode the scene between the editor and exporter.

## Composition model

`CanvasSceneEditor` provides the turnkey scene-editing experience.

For custom document models or editor composition, use
`CanvasEditorSurface<TSourceDocument>` with ordered
`EditorExtension<TSourceDocument>` values.

`CanvasEditorSurface` owns these editor-session inputs:

* `initialDocument`
* `adapter`
* `initialResolveContext`
* `resources`
* ordered `extensions`

These values are editor-session configuration. Use a new key to intentionally
create a session from different values.

`onSceneChanged`, `appBarBuilder`, and shell presentation remain normal widget
inputs.

An `EditorExtension` may contribute:

| Timing                                   | Contribution                                       |
| ---------------------------------------- | -------------------------------------------------- |
| Before `attach`, once per editor session | `scenePreparer`, `fieldCodecs`, `surfaceFeatures`  |
| After `attach`, once per editor session  | `actionSpecs`                                      |
| During widget-tree builds                | `buildProviders`, `inspectorFieldRowBuilder`       |

`EditorSurfaceFeatures` owns live editor-surface behavior: inspector sections
and headers, viewport framing, viewport behavior, interaction policy, selection
chrome, and scene-object presentation.

`scenePreparer` and `fieldCodecs` are direct extension contributions because
they configure runtime scene preparation and document-field semantics.
`EditorRuntime` receives those values as plain constructor inputs and remains
unaware of extension composition.

Extension composition permits at most one non-null `scenePreparer`. Contributing
more than one preparer throws `StateError`; preparation order must not depend on
extension ordering.

The runtime rendering sequence is:

```text
canonical source document
  -> EditorDocumentAdapter.resolve()
  -> optional ScenePreparer
  -> CanvasRenderPipeline.build()
  -> RenderSnapshot
```

The adapter converts the source document into a runtime scene. The preparer may
transform that resolved scene. The render pipeline remains the only owner of
scene computation, paint-operation generation, content bounds, and snapshot
construction.

## Architecture

See [doc/architecture.md](doc/architecture.md) for package entrypoints,
layering, extension, lifecycle, and export guidance.

## Package boundaries

* `canvas_editor_flutter` owns the reusable Flutter editor experience and its
  composition APIs.
* `canvas_core` owns the document model, geometry, scene computation, and
  renderer-agnostic paint operations.
* `canvas_renderer_flutter` owns Flutter drawing, text measurement, image
  helpers, and scene export support.
* Applications own persistence, authentication, analytics, network clients,
  permissions, image processing, media lifecycle, and product-specific
  workflows.

## Localization

The built-in editor interface currently ships with English UI text.

Applications may provide custom surrounding UI and editor chrome. Built-in
inspector, layers, toolbar, dialog, and tooltip strings are not currently
configurable.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).

Copyright 2026 Nijify.
