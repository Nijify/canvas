# canvas_editor_flutter architecture

`canvas_editor_flutter` is a complete Flutter editor for `canvas_core` runtime scenes.
It provides viewport UI, picking, snapping, selection overlays, layers, inspector content, editing actions, history orchestration, runtime resource integration, and composable capability APIs.

The package is product-agnostic. Applications connect persistence, permissions, authentication, analytics, network clients, and workflow decisions at host boundaries.

## Public entrypoints

Turnkey scene editor:

```dart
import 'package:canvas_editor_flutter/canvas_editor_flutter.dart';
```

Composable surfaces, adapters, extensions, shell configuration, actions, inspector content, and interaction policies:

```dart
import 'package:canvas_editor_flutter/extensions.dart';
```

Focused optional capabilities:

```dart
import 'package:canvas_editor_flutter/asset_library.dart';
import 'package:canvas_editor_flutter/image_import.dart';
import 'package:canvas_editor_flutter/image_tools.dart';
```

Do not import `package:canvas_editor_flutter/src/**` from another package.

## Layering

The editor composes three concerns:

1. **Presentation/UI** — viewport widgets, inspector widgets, selection overlays, layers, shortcuts, and editor actions.
2. **Editor runtime/control** — `EditorRuntime`, history, picking, snapping, document adapters, scene mutations, and interactive render publication.
3. **Host integration** — runtime resources, image acquisition/tools, curated assets, output destinations, persistence, networking, and product workflows.

The editor package depends on `canvas_renderer_flutter` for Flutter rendering services and on `canvas_core` for document/runtime contracts. It does not hide renderer ownership by re-exporting renderer APIs from its turnkey barrel.

## Runtime resources

`CanvasRuntimeResources` is a passive capability bundle:

```text
CanvasRuntimeResources
  -> FlutterFontLoader fonts
  -> List<FontPickerItem> pickerFonts
  -> IconCatalogPort icons
  -> CanvasImageAssetResolver images
```

`FlutterFontLoader` is renderer-owned because font registration is a Flutter rendering concern. `FontPickerItem` remains editor-owned presentation metadata. `CanvasImageAssetResolver` is core-owned because logical image source identity is renderer-neutral.

`CanvasEditorSurface` owns its long-lived `FlutterTextPipeline` and `FlutterImagePool`. It also owns the pool's intrinsic-update subscription because the notification lifecycle belongs with the concrete pool owner. `EditorRuntime` only consumes `CanvasRenderPipeline` and does not subscribe to image-resource streams.

`EditorAssetCoordinator` discovers required scene font families, asks the shared font loader to ensure them, starts best-effort intrinsic metadata resolution, and preloads visible raster state. Optional intrinsic metadata does not block raster loading for the interactive editor.

## Canonical, resolved, and prepared scenes

The editor distinguishes three useful scene states:

- **canonical/base scene** — editable state used for history, persistence, object-tree UI, and scene JSON export;
- **resolved scene** — output of `EditorDocumentAdapter.resolve()` using the current source document and resolve context;
- **prepared scene** — optional runtime transformation of the resolved scene used by interactive rendering.

Prepared state is not canonical persistence state.

### Interactive rendering

```text
current source document
  -> EditorDocumentAdapter.resolve()
  -> optional ScenePreparer
  -> CanvasRenderPipeline.build()
  -> RenderSnapshot
  -> CanvasRenderer
```

The preparer receives the exact stable `CoreServices` instance retained by the render pipeline. Extension composition permits at most one non-null preparer.

### Authoritative PNG output

```text
current source document
  -> EditorDocumentAdapter.resolve()
  -> EditorController.resolveSceneForOutput()
  -> PngExportPort
  -> CanvasPngRenderer
  -> optional ScenePreparer exactly once inside final rendering
```

`resolveSceneForOutput()` resolves the latest current source state, including the active transaction/history present value, and deliberately stops before preparation.

`PngExportPort` receives one adapter-resolved, unprepared `CanvasSceneDocument`, `CanvasPngSpec`, and output metadata. It does not receive separate editable and prepared scenes.

This boundary prevents three failure modes:

- exporting stale base state when adapter resolution matters;
- treating interactive prepared state as canonical output input;
- invoking the same `ScenePreparer` twice.

JSON export remains based on canonical editable/base state.

## Mutation model

Registered fields and structural scene edits both mutate the canonical/base
scene, but they use different editor-owned paths.

`getField()` is a presentation read and may return a value from the resolved or
prepared runtime scene. It must not be used as the starting value for a
canonical read-modify-write operation.

`commitField()` and `updateField()` share one runtime-owned canonical field
mutation path. `updateField()` reads the current value from the latest
transaction-present canonical base scene before invoking its updater.
`FieldCodec` owns field applicability, canonical reads, normalization, and the
commit-free canonical scene writer.

```text
Registered literal field
  -> commitField
  -> runtime canonical field mutation
  -> FieldCodec canonical writer
  -> EditorDocumentAdapter.replaceBase
  -> history/publication

Registered functional field update
  -> updateField
  -> FieldCodec canonical reader
  -> updater
  -> FieldCodec canonical writer
  -> EditorDocumentAdapter.replaceBase
  -> history/publication

Structural/custom base-scene operation
  -> EditorEdit
  -> EditorController.applyEdit
  -> history/publication

Source-document state outside base scene
  -> EditorDocumentHost.applySourceEdit
  -> base-preservation guard
  -> history/publication
```
Canonical `FieldCodec` writers return a transformed base scene and do not start
another editor commit.

`EditorDocumentHost.applySourceEdit()` is reserved for host-owned source state
outside the base scene. Its callback runs inside the runtime commit against the
latest transaction-present source document. A source edit that meaningfully
changes the adapter's canonical base scene throws before history or publication
changes.

Source-only changes still pass through source and render publication so adapter
resolution, field editability, and other source-derived editor state can
refresh. The canonical `document` listenable does not publish when the base
scene remains value-equal.

Drag, rotate, and scale interactions use ephemeral edit sessions so repeated
pointer updates render immediately but commit one history entry when the
session closes.

## Extension model

`EditorExtension<TSourceDocument>` is the composition seam for custom editor behavior.

Construction-time contributions include:

- `scenePreparer`
- `fieldCodecs`
- `surfaceFeatures`

After attachment, extensions may contribute action specs and providers. Inspector/build hooks may depend on state initialized during `attach`.

`EditorRuntime` remains independent of extension composition; `CanvasEditorSurface` resolves extension contributions and passes plain runtime inputs into it.

## Capability model

- `asset_library.dart` provides curated catalog contracts and insertion behavior.
- `image_import.dart` provides host-owned image acquisition and replacement.
- `image_tools.dart` provides host-owned destructive transformations such as background removal.
- `PngExportCapability` and `JsonExportCapability` add host-owned output actions.

Image tools operate on logical source references. Applications own image access, remote processing, encoding, storage, provider lifecycle, and cleanup. Canvas owns target validation, stale-result rejection, registered-field semantics, and undoable adoption of accepted results.

## Session lifecycle

`CanvasSceneEditor` and `CanvasEditorSurface` each create one uncontrolled editor session. Initial document/source configuration, runtime resources, and extension composition are captured when the session is created. Same-key rebuilds preserve the active document and resource graph; use a new key to intentionally replace the session.

## Package boundaries

- `canvas_editor_flutter` owns reusable editor interaction, runtime orchestration, and presentation, including history, picking, snapping, selection, gestures, and derived world interaction geometry.
- `canvas_core` owns runtime documents, document/render geometry, scene computation, logical resource contracts, and renderer-neutral paint operations.
- `canvas_renderer_flutter` owns Flutter drawing, font/text implementations, decoded raster ownership, and canonical final PNG rendering.
- Applications own product-specific storage, authentication, networking, permissions, analytics, media/font lifecycle, processing, and workflow decisions.
