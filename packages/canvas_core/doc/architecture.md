# canvas_core architecture

`canvas_core` is a pure-Dart canvas document engine. It owns the runtime scene model, geometry primitives, deterministic scene computation, hit testing, snapping, viewport math, serialization, logical resource contracts, and renderer-agnostic paint operations.

The package is complete on its own: apps can create `CanvasSceneDocument` values, serialize them, compute scene geometry, build paint operations, and layer editor interactions over the same runtime data without any product-specific package.

## Public entrypoints

Runtime API:

```dart
import 'package:canvas_core/canvas_core_runtime.dart';
```

Headless editor helpers:

```dart
import 'package:canvas_core/canvas_core_editor.dart';
```

Public consumers should not import `package:canvas_core/src/**`.

## Runtime pipeline

`CanvasRenderPipeline` owns deterministic scene computation, paint-op generation, optional content bounds, and `RenderSnapshot` construction.

```text
CanvasSceneDocument
  -> optional host-invoked ScenePreparer
  -> CanvasRenderPipeline.build()
  -> RenderSnapshot
  -> renderer-specific PaintOp replay
```

`CanvasRenderPipeline.services` is constructed once with the pipeline and remains stable for its lifetime. Hosts may pass this exact service bundle to a `ScenePreparer` before `build()`.

The generic pipeline does not invoke preparation itself. High-level renderer/editor layers decide where preparation belongs. In particular, an authoritative final-output renderer may own the preparation call so callers cannot accidentally render an already-prepared scene twice.

## Host services and logical resources

Core stays platform-neutral. `CoreServices` exposes synchronous capabilities needed during scene computation:

- `TextMeasurer textMeasurer`
- optional `ImageIntrinsics images`
- optional `IconResolver icons`

`ImageIntrinsics` is synchronous lookup only. Resource loading, retries, caches, and notifications belong outside core.

`CanvasImageAssetResolver` is a separate asynchronous host boundary for logical canvas image resources:

```text
logical sourceRef
  -> CanvasImageAssetResolver
  -> host-renderable runtime source
```

Resolver inputs are opaque logical `sourceRef` values stored in the document. `resolveSources()` results may be temporary or rotating runtime values such as signed URLs or blob URLs and must not be treated as persistent identity. `resolveIntrinsicSizes()` provides stable layout-affecting metadata keyed by the logical ref. Both result maps may be partial.

`collectSceneFontFamilies()` discovers logical font-family dependencies from nested and hidden text plus resolved font-backed icons. Discovery does not load or validate fonts.

## Serialization boundary

External and persisted document JSON crosses the runtime boundary through:

```text
external JSON -> decodeCanvasScene -> CanvasSceneDocument
CanvasSceneDocument -> encodeCanvasScene -> external JSON
```

Generated model serializers remain implementation-level primitives. Semantic document validation stays explicit and follows decoding when a caller requires it.

## Headless interaction utilities

`canvas_core_editor.dart` exposes interaction mechanics over runtime scenes, including history, hit testing, picking, and snapping. These helpers consume the same computed scene data used for rendering so interactive behavior stays aligned with visual output.

## Package boundaries

- `canvas_core` is Dart-only and does not import Flutter, `dart:ui`, widgets, files, HTTP, or renderer-specific APIs.
- Runtime APIs operate on `CanvasSceneDocument`, `Node`, and renderer-neutral value types.
- Core owns logical resource contracts but does not load platform resources.
- Renderers consume `PaintOp` values instead of reimplementing scene traversal, transforms, layout, or z-order.
- Apps/editors own when to resolve host data, prepare scenes, and invoke final rendering.

## Data flows

General rendering:

```text
Host/app data
  -> CanvasSceneDocument
  -> optional ScenePreparer with pipeline.services
  -> CanvasRenderPipeline.build()
  -> RenderSnapshot
  -> renderer
```

Interaction:

```text
CanvasSceneDocument + ComputedScene
  -> pickTopAtScene / snapScene / History
  -> updated CanvasSceneDocument
  -> computeScene(...)
```

Keeping rendering and interaction on the same computed scene prevents drift between what users see and what the editor can select, snap, or manipulate.
