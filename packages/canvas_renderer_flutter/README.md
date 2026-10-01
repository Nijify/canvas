# canvas_renderer_flutter

`canvas_renderer_flutter` is the Flutter rendering adapter for `canvas_core`. It provides low-level paint-op replay, Flutter text measurement/painting, decoded image ownership, font loading, and the canonical final PNG rendering boundary.

## Features

- `CanvasRenderer` for replaying `PaintOp` values onto a Flutter `Canvas`.
- `FlutterTextPipeline` for Flutter text measurement, painting, caching, and lifecycle ownership.
- `FlutterImagePool` for decoded raster ownership, intrinsic metadata, repaint notifications, stale-request protection, and image disposal.
- `FlutterFontLoader` for host-controlled font availability, with `BundledFlutterFontLoader` for bundled assets.
- `CanvasPngRenderer` / `FlutterCanvasPngRenderer` for authoritative final PNG output from a canonical runtime scene.
- Core-to-Flutter value mappers and optional `ImageProvider` helpers.

## Installation

```bash
flutter pub add canvas_renderer_flutter canvas_core
```

## Imports

```dart
import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
```

Do not import files under `package:canvas_renderer_flutter/src/`.

Optional image-provider helpers live behind:

```dart
import 'package:canvas_renderer_flutter/canvas_renderer_flutter_image_providers.dart';
```

## Low-level rendering

`CanvasRenderer` replays paint operations produced by `canvas_core`. It borrows text, image, and intrinsic resources; it does not own or dispose them.

Use one `FlutterTextPipeline` for both core measurement and Flutter text painting:

```dart
final textPipeline = FlutterTextPipeline(
  fallbackFontFamilies: const ['Noto Sans'],
);

final renderPipeline = CanvasRenderPipeline(
  textMeasurer: textPipeline,
);

final snapshot = renderPipeline.build(document);

final renderer = CanvasRenderer(
  text: textPipeline,
);

renderer.replay(canvas, snapshot.ops);
```

The creator owns `FlutterTextPipeline` and must dispose it. Long-lived editor/preview surfaces may reuse one pipeline and clear its cache when Flutter font availability changes.

## Fonts

Final rendering should use an explicit `FlutterFontLoader` so logical canvas font families are available before layout and preparation.

For bundled application assets:

```dart
final fonts = BundledFlutterFontLoader(
  fonts: const [
    BundledFlutterFont(
      family: 'Inter',
      assetPaths: [
        'assets/fonts/Inter-Regular.ttf',
        'assets/fonts/Inter-Bold.ttf',
      ],
    ),
  ],
  fallbackFontFamilies: const ['Inter'],
);
```

`BundledFlutterFontLoader` validates requested families, shares in-flight registrations, caches successful loads, and leaves failed loads retryable. Hosts may implement `FlutterFontLoader` differently for remote fonts, local caches, or other font sources.

## Image resources

`FlutterImagePool` accepts the core-owned `CanvasImageAssetResolver` contract:

```dart
final imagePool = FlutterImagePool(
  resolver: appImageResolver,
);

await imagePool.resolveSceneIntrinsics(
  document,
  includeHidden: true,
);

await imagePool.preloadScene(
  document,
  targetW: 2048,
  targetH: 2048,
);
```

`CanvasImageAssetResolver` receives opaque logical `sourceRef` values from the canvas document. Resolver maps are keyed by the exact input refs.

`resolveSources()` returns host-renderable runtime references. They may be temporary or rotating values such as signed URLs or blob URLs, so `FlutterImagePool` resolves active logical refs again for each preload operation instead of treating resolved outputs as persistent identity.

`resolveIntrinsicSizes()` supplies stable layout-affecting metadata keyed by logical source ref. `FlutterImagePool` may cache that metadata while decoded raster state remains keyed to document element IDs.

The two notification channels have different meanings:

- `onIntrinsicUpdated` reports layout-affecting metadata changes.
- `revision` reports paint-only decoded raster changes.

Dispose a pool when its rendering surface or render operation ends. The pool owns and disposes decoded `ui.Image` handles retained by it, including replaced, removed, stale, and late-arriving images.

### Image-loading results (Unreleased)

`resolveSceneIntrinsics()` and `preloadScene()` now return immutable
`List<FlutterImageLoadFailure>` values. Each result describes only that loading
operation; the pool retains no diagnostic history. Successful operations return
an empty list. Superseded or disposed operations also return an empty list, so
it is not a readiness signal for an obsolete request.

```dart
final failures = await imagePool.preloadScene(document);
for (final failure in failures) {
  // Safe library-generated summary: phase, reason, and cause type.
  debugPrint(failure.toString());
}
```

Failures distinguish source resolution, intrinsic metadata, and raster decoding,
including missing/empty results and thrown errors. `sourceRef` identifies the
logical resource; `cause` and `stackTrace` retain the original exception and
available stack trace. These structured fields may contain inline data, private
paths, or signed-URL credentials; redact them before logging or transmitting.

Interactive callers can continue awaiting these methods and ignore the results.
Metadata remains best-effort and does not gate raster loading. Use a new
operation to retry; no diagnostic reset is needed. Retained earlier results are
historical operation results, not a view of the current pool state.

## Canonical PNG rendering

Use `FlutterCanvasPngRenderer` for authoritative final output:

```dart
final pngRenderer = FlutterCanvasPngRenderer(
  fonts: fonts,
  icons: appIcons,
  images: appImageResolver,
  scenePreparer: scenePreparer,
);

final bytes = await pngRenderer.renderPng(
  scene: resolvedCanonicalScene,
  spec: const CanvasPngSpec(
    widthPx: 1080,
    heightPx: 1080,
    pixelRatio: 2,
    transparent: true,
  ),
);
```

The supplied scene should already be the host/adapter-resolved canonical runtime scene, but it must be **unprepared**. `FlutterCanvasPngRenderer` owns final-output preparation.

Its render operation performs, in order:

1. canonical structural validation;
2. canonical font, icon, and logical image dependency discovery;
3. canonical font loading and icon validation;
4. canonical image-intrinsic resolution;
5. `ScenePreparer` exactly once, when configured;
6. prepared-scene validation and resource-preservation checks;
7. a second prepared image-intrinsic pass for new element IDs that reuse allowed logical sources;
8. visible raster preload and strict required-image verification;
9. layout, paint replay, PNG encoding, and operation-scoped cleanup.

Preparation may remove dependencies or introduce new element/asset IDs that reuse already-approved logical resources. It may not introduce new font families, icon refs, or active image `sourceRef` dependencies.

`CanvasPngSpec` intentionally does not expose low-level missing-resource renderer options. Final output is strict; tolerant placeholder behavior remains available to interactive/preview surfaces through low-level `CanvasRenderer` configuration.

Required-image failures throw `CanvasImageRenderException`, a `StateError`
subtype. It exposes the missing `nodeIds` and relevant operation `failures`,
including original causes when available. Formatted errors omit raw sources and
original exception text. The renderer still applies its existing requirements
before failing: persisted dimensions may satisfy metadata needs, hidden final
images need no raster, and intentionally empty frames are valid. Font-loader
and preparer exceptions continue to propagate directly.

## Optional ImageProvider helpers

### Failure and file-reference migration (Unreleased)

`toUiImage()` propagates provider, image-stream, and clone errors rather than
turning them into null. Direct callers should handle exceptions; dispose any
successfully returned image as before. `FlutterImagePool` catches these errors
and returns operation-local failures, preserving best-effort interactive loading.

`sourceToProvider()` accepts the unconverted file reference. On native targets,
its IO adapter converts file URIs using the executing platform's path rules;
conversion errors propagate instead of falling back to a literal URI filename.
Raw paths remain unchanged. Unsupported targets reject file-backed loading.
Pass `CanvasFileAssetRef.raw` rather than the removed `.path` field. This does
not change stored scene sources or add home-directory expansion.

The optional helpers convert common renderable refs to Flutter `ImageProvider` values:

```text
asset:assets/samples/image.png
assets/samples/image.png
data:image/png;base64,...
https://example.com/image.png
blob:https://example.com/...
file:///tmp/image.png
```

Support for `blob:` and `file:` depends on the Flutter target platform. App-specific logical refs such as `media:abc123` should be resolved by the host through `CanvasImageAssetResolver` before provider conversion.

## Package boundaries

- `canvas_renderer_flutter` depends on `canvas_core` and does not depend on editor UI.
- `canvas_core` owns logical scene/resource contracts; this package owns Flutter resource implementations and drawing.
- Hosts own storage, authentication, networking, signed-URL refresh, media IDs, persistence, and product concepts.
- `CanvasRenderer` is a public low-level paint-op replayer.
- `FlutterCanvasPngRenderer` is the high-level authoritative final PNG boundary.
- `FlutterTextPipeline` and `FlutterImagePool` own their respective Flutter resources and must be disposed by their creators, except when created internally by `FlutterCanvasPngRenderer`.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).

Copyright 2026 Nijify.
