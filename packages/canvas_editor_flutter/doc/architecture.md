# canvas_editor_flutter architecture

`canvas_editor_flutter` is a complete Flutter editor for `canvas_core` runtime
scenes. It provides viewport UI, selection overlays, layers, inspector content,
editing actions, history orchestration, runtime resource integration, and
composable capability APIs.

The package is product-agnostic. Applications connect persistence, permissions,
authentication, analytics, network clients, and workflow decisions at the host
boundary while using the package's public entrypoints for editor composition.

## Public entrypoints

For the turnkey scene editor:

```dart
import 'package:canvas_editor_flutter/canvas_editor_flutter.dart';
```

For composable editor surfaces, document adapters, extensions, shell
configuration, inspector content, actions, and interaction policies:

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

The capability entrypoints are additive. The turnkey entrypoint remains a
complete scene editor without them.

Do not import `package:canvas_editor_flutter/src/**` from another package.

## Main APIs

### `CanvasSceneEditor`

Use `CanvasSceneEditor` for turnkey scene editing. It accepts an initial
`CanvasSceneDocument`, runtime resources, extensions, export capabilities, and a
document-change callback.

```dart
Widget build(BuildContext context) {
  return CanvasSceneEditor(
    initialScene: scene,
    resources: resources,
    onSceneChanged: (updatedScene) {
      persistScene(updatedScene);
    },
  );
}
```

Capabilities compose through extensions or dedicated constructor inputs:

```dart
CanvasSceneEditor(
  initialScene: scene,
  resources: resources,
  extensions: [
    imageImportExtension(imageImport: imageImport),
    canvasAssetLibraryExtension(
      library: assetLibrary,
      presentSelection: presentAssetSelection,
    ),
  ],
  pngExport: pngExport,
  jsonExport: jsonExport,
)
```

### `CanvasEditorSurface<TSourceDocument>`

Use `CanvasEditorSurface` when the editor should operate on a custom source
document or use a custom composition of adapters, extensions, shell
configuration, and interaction behavior while retaining the same editor
runtime and UI components.

## Layering model

`canvas_editor_flutter` composes three concerns:

1. **Presentation/UI**: viewport widgets, inspector widgets, selection overlays,
   editor actions, keyboard shortcuts, layers, and shell presentation.
2. **Editor runtime/control orchestration**: `EditorRuntime`, history,
   render/update coordination, document adapters, and scene mutations.
3. **Application boundary integration**:

   * runtime resources: media/source resolution, font loading, and icon catalogs;
   * capabilities: asset selection, image acquisition, PNG export, and JSON
     export;
   * product workflows: persistence, permissions, networking, and surrounding
     application UI.

## Rendering and editing flow

```text
Application
  -> CanvasSceneEditor
  -> CanvasEditorSurface<CanvasSceneDocument>
  -> EditorRuntime<CanvasSceneDocument>
  -> canvas_core compute/render contracts
  -> canvas_renderer_flutter drawing/export support
```

The editor mutates `CanvasSceneDocument` values directly. It delegates
deterministic geometry and paint planning to `canvas_core`, then delegates
Flutter drawing and image/text helpers to `canvas_renderer_flutter`.

## Mutation model

Persistent base-scene changes use one execution seam:
`EditorController.applyEdit`.

Canonical source-document state outside the base scene is updated through
`EditorDocumentHost.updateSourceDocument`.

Choose the caller-facing API according to the operation:

```text
Registered editable property
  -> commitField
  -> FieldCodec
  -> EditorEdit
  -> applyEdit

Structural, multi-node, or custom base-scene operation
  -> EditorEdit
  -> applyEdit

Source-document state outside the base scene
  -> EditorDocumentHost.updateSourceDocument

Pointer transform
  -> ephemeral transform method
  -> active edit session
  -> one committed history entry
```

### Registered fields

A property represented by a `CanvasFieldKey` is edited through `commitField`.
Its `FieldCodec` owns field-specific behavior, including:

* reading the effective rendered value;
* validating or normalizing literal values;
* preserving related canonical values;
* converting the field change into an `EditorEdit`.

Built-in and extension inspector controls must not call `applyEdit` directly for
a registered field because doing so would bypass codec overrides and
field-specific policy.

A `CanvasFieldKey` identifies an editable property, and its `FieldCodec` defines
that property's literal editing behavior.

### Generic base-scene edits

Use `applyEdit` directly for base-scene operations that are not individual
registered properties, such as adding, deleting, duplicating, reordering, or
replacing scene nodes, and for operations spanning multiple nodes or
properties.

Use `EditorDocumentHost.updateSourceDocument` only for canonical source-document
state that is not represented by the base `CanvasSceneDocument`.

`applyEdit` owns persistent mutation execution: history, canonical base-scene
replacement, document-adapter hooks, and render publication. It does not expose
type-specific text, icon, image, path, fill, or background mutation methods.

### Ephemeral transforms

Drag, rotate, and scale updates remain runtime-owned ephemeral operations.
Repeated pointer updates are rendered immediately inside an edit session and
committed as one undoable history entry when the session closes.

Field reads may use the effective rendered scene. Field validation and writes
target the current canonical document.

## Editor session lifecycle

`CanvasSceneEditor` and `CanvasEditorSurface` each create one uncontrolled
editor session.

The initial document, adapter and resolve context, runtime resources, and
extension composition are captured when the session is created. Same-key widget
rebuilds preserve the active document and resource graph.

A new widget key disposes the old editor session—including history, selection,
camera, renderer/image caches, and extension-owned state—and creates a fresh
session from the supplied configuration.

Callbacks and shell presentation remain normal widget inputs.

## Extension model

`EditorExtension<TSourceDocument>` is the capability-composition seam for custom
editor behavior.

Construction-time contributions are read once before `attach`:

* `renderBuilder`
* `fieldCodecs`
* `surfaceFeatures`

`EditorSurfaceFeatures` aggregates live editor-surface configuration:

* inspector composition;
* viewport framing and behavior;
* interaction policy;
* selection chrome;
* scene-object presentation policy.

The standard scene-editing actions and inspector are intrinsic to
`CanvasEditorSurface`. Ordered extensions then contribute custom runtime
configuration, providers, inspector rows, actions, and capabilities.

Extension `actionSpecs` are read after `attach`, appended to the intrinsic
actions, validated for duplicate IDs, and frozen for the editor session.

`buildProviders` and `inspectorFieldRowBuilder` are build-time hooks. They may
depend on state created in `attach` and may be read again after an extension
requests a rebuild.

`EditorRuntime` does not depend on extensions. It receives a render builder and
field codecs as plain constructor inputs.

## Capability model

Capability entrypoints provide focused integrations without changing the core
editor model:

* `asset_library.dart` provides curated catalog contracts and asset insertion;
* `image_import.dart` provides image acquisition and replacement;
* PNG and JSON export capabilities add editor export actions.

Applications provide environment-specific implementations such as picker UI,
file access, durable media storage, and output destinations. The editor owns the
shared document behavior after those integrations return a result.

## Package boundaries

* `canvas_editor_flutter` owns the reusable Flutter editor experience and its
  composition APIs.
* `canvas_core` owns the runtime document model, geometry, scene computation,
  and renderer-agnostic paint operations.
* `canvas_renderer_flutter` owns Flutter drawing, image helpers, text
  measurement, and render/export support.
* Applications own product-specific persistence, permissions, authentication,
  analytics, networking, and workflow decisions.
