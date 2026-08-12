## 0.7.0

- **Breaking:** require `canvas_core 0.8.x`.
- No rendering behavior changes.

## 0.6.0

- **Breaking:** require `canvas_core 0.7.x`.
- Support the explicit component behavior `version` and `data` envelope introduced by `canvas_core 0.7.0`.

## 0.5.0

- **Breaking:** require `canvas_core 0.6.x`.
- **Breaking:** stop re-exporting `CanvasFit` and `ContentBoundsPolicy`.
  Import these core-owned types from `canvas_core_runtime.dart`.
- **Breaking:** require one typed `CanvasSceneDocument` in
  `CanvasDocumentExporter.exportPng()` and remove the `documentJson` input.
- **Breaking:** remove exporter-level `renderBuilder` support. Callers that
  use scene preparation must supply the already-prepared runtime scene.
- Render the supplied scene directly through `CanvasRenderPipeline.build()`.
- Consume the `CanvasViewportTransform` returned directly by
  `CanvasViewportPlanner.plan()`.

## 0.4.0

- **Breaking:** make `FlutterTextPipeline` implement the core `TextMeasurer`
  contract directly.
- **Breaking:** remove `FlutterTextMeasurer`, `TextMetrics`, and the previous
  `FlutterTextPipeline.measure(TextSpec)` API.
- **Breaking:** require a caller-owned `FlutterTextPipeline` when constructing
  `CanvasRenderer` and `CanvasDocumentExporter`.
- **Breaking:** remove `fallbackFontFamilies` from
  `CanvasDocumentExporter`; fallback fonts are configured on the supplied text
  pipeline instead.
- Dispose cached `TextPainter` instances during LRU eviction, cache clearing,
  and pipeline disposal.
- Dispose operation-scoped shadow, solid-color, and gradient text painters
  after painting.
- Add reusable `clearCache()` and idempotent terminal `dispose()` lifecycle
  behavior.
- Throw `StateError` when measurement or painting is attempted after pipeline
  disposal.
- Reject non-positive text-layout cache limits with `ArgumentError` in all
    build modes.

## 0.3.1

- Make PNG output image cleanup exception-safe.
- Document that export input images remain caller-owned.

## 0.3.0

- **Breaking:** make `FlutterImagePool` the sole owner of decoded images and
  stable intrinsic image metadata.
- Remove `FlutterImageIntrinsics` and the separate `intrinsics` method
  parameters.
- Expose decoded images through a live, read-only map.
- Add injectable image decoding with explicit ownership transfer.
- Dispose replaced, removed, stale, late, and retained image handles.
- Prevent older intrinsic and raster requests from overwriting newer state.

## 0.2.0

- **Breaking:** require `canvas_core 0.4.x`.
- Replace pre-expanded text with native `double` letter spacing.
- Forward letter spacing through measurement, caching, and painting.

## 0.1.1

- Expand the supported `canvas_core` range to include `0.3.x`.
- No renderer behavior or API changes.

## 0.1.0

- Initial open-source release of canvas_renderer_flutter.
- Provides Flutter rendering, text measurement, decoded image caching, image intrinsic helpers, and PNG export support for canvas_core scenes.
- Includes optional ImageProvider helpers behind a separate import for apps that want to resolve common image refs across mobile and web.
