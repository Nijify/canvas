# canvas_renderer_flutter

`canvas_renderer_flutter` is the Flutter rendering adapter for `canvas_core`. It replays renderer-agnostic paint operations onto a Flutter `Canvas`, provides Flutter-backed text measurement and painting, manages decoded image caches, and exports canvas scenes to PNG.

## Features

- `CanvasRenderer` for drawing `PaintOp` lists on a `dart:ui` canvas.
- `FlutterTextPipeline` as the shared Flutter text measurement, painting, caching, and resource-ownership engine.
- `FlutterImagePool` for decoded raster ownership, stable intrinsic metadata, repaint notifications, asynchronous request ordering, and image disposal.
- `CanvasDocumentExporter` for PNG export from a `CanvasSceneDocument` or scene JSON.
- Core-to-Flutter value mappers for colors, rects, sizes, offsets, and gradients.
- Optional `ImageProvider` helpers for apps that want to convert common image refs into Flutter `ImageProvider`s.

## Installation

Add the package to a Flutter app or package:

```bash
flutter pub add canvas_renderer_flutter canvas_core
```

## Imports

Use the main renderer barrel for rendering, export, text, image-pool, gradient, and mapper APIs:

```dart
import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
```

Do not import files under `package:canvas_renderer_flutter/src/`; use the public barrels.

Optional image-provider helpers live behind a separate import:

```dart
import 'package:canvas_renderer_flutter/canvas_renderer_flutter_image_providers.dart';
```

Use that optional import only when your app wants to convert string image refs such as `asset:`, `data:`, `http(s):`, `blob:`, or platform-supported `file:` refs into Flutter `ImageProvider`s.

## Text pipeline ownership

`FlutterTextPipeline` is the Flutter implementation of the `canvas_core` `TextMeasurer` contract. The same instance is also used by `CanvasRenderer` when painting text.

It owns a bounded cache of Flutter `TextPainter` layouts and must be disposed by the caller that creates it:

```dart
final textPipeline = FlutterTextPipeline(
  fallbackFontFamilies: const ['Noto Sans'],
);

try {
  // Measure, build, and paint scenes with textPipeline.
} finally {
  textPipeline.dispose();
}
```

`CanvasRenderer` and `CanvasDocumentExporter` only borrow the pipeline supplied to them. They never clear or dispose it.

Use one long-lived pipeline per editor or rendering surface. For operation-scoped work such as PNG export, create one pipeline for the operation and dispose it in `finally`.

If new fonts are registered while a pipeline is alive, clear its cached layouts before scheduling layout again:

```dart
textPipeline.clearCache();
scheduleLayoutInvalidation();
```

`clearCache()` releases cached text layouts while keeping the pipeline reusable. `dispose()` permanently closes the pipeline and is safe to call more than once.

## Render paint operations in a CustomPainter

Pass the same text pipeline used for core layout to the Flutter renderer:

```dart
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter/widgets.dart';

class ScenePainter extends CustomPainter {
  ScenePainter({
    required this.ops,
    required this.images,
    required this.textPipeline,
  });

  final List<PaintOp> ops;
  final Map<ElementId, ui.Image?> images;
  final FlutterTextPipeline textPipeline;

  @override
  void paint(Canvas canvas, Size size) {
    CanvasRenderer(
      images: images,
      text: textPipeline,
    ).replay(canvas, ops);
  }

  @override
  bool shouldRepaint(ScenePainter oldDelegate) {
    return oldDelegate.ops != ops ||
        oldDelegate.images != images ||
        oldDelegate.textPipeline != textPipeline;
  }
}
```

Build the paint operations with `CanvasRenderPipeline` and the same text pipeline:

```dart
final textPipeline = FlutterTextPipeline();

final renderPipeline = CanvasRenderPipeline(
  textMeasurer: textPipeline,
);

final snapshot = renderPipeline.build(document);
final ops = snapshot.ops;
```

The object that owns the rendering surface must dispose `textPipeline` when that surface is torn down.

## Manage image state with FlutterImagePool

`FlutterImagePool` is the single owner of decoded raster images and stable intrinsic image metadata for a rendering surface.

```dart
final textPipeline = FlutterTextPipeline();

final imagePool = FlutterImagePool(
  assetUrlResolver: resolveImageUrl,
  assetMetaResolver: resolveIntrinsicSize,
);

await imagePool.resolveSceneIntrinsics(document);

await imagePool.preloadScene(
  document,
  targetW: 2048,
  targetH: 2048,
);

final renderPipeline = CanvasRenderPipeline(
  textMeasurer: textPipeline,
  images: imagePool,
);

final snapshot = renderPipeline.build(document);

final renderer = CanvasRenderer(
  images: imagePool.images,
  text: textPipeline,
  intrinsics: imagePool,
);
```

The two image notification channels have different meanings:

- `imagePool.onIntrinsicUpdated` reports layout-affecting metadata changes.
- `imagePool.revision` reports paint-only decoded raster changes.

`images` is a live, read-only map. A renderer that retains the map continues to observe later pool updates, but external consumers cannot mutate it.

Dispose resources when the rendering surface is torn down:

```dart
imagePool.dispose();
textPipeline.dispose();
```

Disposing the pool releases every decoded `ui.Image` handle retained by it. Replaced, removed, stale, and late-arriving images are also disposed automatically.

Use one pool per editor, thumbnail, or other document rendering surface. Image state is keyed by document-local element IDs and should not be shared between unrelated documents.

## Export a scene to PNG

Create an operation-scoped text pipeline and keep it alive until `exportPng()` completes:

```dart
Future<Uint8List> exportExample(
  CanvasSceneDocument document,
) async {
  final textPipeline = FlutterTextPipeline(
    fallbackFontFamilies: const ['Noto Sans'],
  );

  final exporter = CanvasDocumentExporter(
    textPipeline: textPipeline,
  );

  try {
    return await exporter.exportPng(
      document: document,
      resolveImage: (id) async => imageCache[id],
      resolveIntrinsicSize: (id) async => intrinsicSizes[id],
      spec: const CanvasExportSpec(
        widthPx: 1080,
        heightPx: 1080,
      ),
    );
  } finally {
    textPipeline.dispose();
  }
}
```

The exporter accepts decoded images separately from intrinsic image sizes. Stable intrinsic metadata affects layout; decoded `ui.Image` dimensions are used only for painting.

Images returned by `resolveImage` are borrowed:

- The caller retains ownership of each image handle.
- Images must remain valid until `exportPng()` completes.
- The exporter never disposes resolved input images.
- The caller remains responsible for disposing those images.

When using an operation-scoped `FlutterImagePool`, await the export before disposing either the image pool or text pipeline:

```dart
final textPipeline = FlutterTextPipeline();
final imagePool = FlutterImagePool(
  assetUrlResolver: resolveImageUrl,
  assetMetaResolver: resolveIntrinsicSize,
);

final exporter = CanvasDocumentExporter(
  textPipeline: textPipeline,
);

try {
  await imagePool.resolveSceneIntrinsics(document);

  await imagePool.preloadScene(
    document,
    targetW: 2160,
    targetH: 2160,
  );

  return await exporter.exportPng(
    document: document,
    resolveImage: (id) async => imagePool.images[id],
    resolveIntrinsicSize: (id) async => imagePool.intrinsicSize(id),
    spec: const CanvasExportSpec(
      widthPx: 1080,
      heightPx: 1080,
      pixelRatio: 2,
    ),
  );
} finally {
  imagePool.dispose();
  textPipeline.dispose();
}
```

## Optional ImageProvider helpers

The core renderer works with decoded `ui.Image` objects and host-provided resolvers. Apps that want a simple loading path can import the optional image-provider helpers:

```dart
import 'package:canvas_renderer_flutter/canvas_renderer_flutter_image_providers.dart';

Future<int?> loadingExample() async {
  final provider = sourceToProvider(
    'https://example.com/image.png',
  );

  final image = await toUiImage(provider);
  if (image == null) return null;

  try {
    return image.width;
  } finally {
    image.dispose();
  }
}
```

`toUiImage()` returns an independently owned image handle. The caller must dispose that handle when it is no longer needed. Images returned to `FlutterImagePool` through its decoder transfer ownership to the pool and are disposed by it.

These helpers support common refs such as:

```text
asset:assets/samples/image_01.png
assets/samples/image_01.png
packages/my_package/assets/image_01.png
data:image/png;base64,...
https://example.com/image.png
blob:https://example.com/...
file:///tmp/image.png
```

Platform notes:

- `asset:`, Flutter asset paths, `data:`, and `http(s):` refs are supported where Flutter supports the corresponding `ImageProvider`.
- `blob:` refs are mainly useful on web and depend on the current Flutter platform’s image loading support.
- `file:` refs and raw local file paths are IO-platform only.
- Web hosts should resolve file-backed or app-specific media refs to `asset:`, `data:`, `blob:`, or `http(s):` before rendering.

## Image source boundaries

`canvas_renderer_flutter` treats canvas image source refs as opaque renderer inputs. App-specific meanings belong outside this package.

For example, the renderer should not know what these mean:

```text
media:abc123
myapp://image/42
db:image-row-id
```

Host apps should resolve those refs before rendering, usually by providing resolver callbacks to `FlutterImagePool` or by passing decoded images directly to lower-level rendering and export APIs.

A typical flow is:

```text
Canvas document image ref
  -> host/app resolver
  -> renderable ref or decoded ui.Image
  -> canvas_renderer_flutter
```

## Boundaries

- This package may use Flutter painting APIs and `dart:ui`.
- It depends on `canvas_core` contracts and does not depend on editor UI.
- The renderer does not know app storage, repositories, authentication, media IDs, product concepts, or persistence workflows.
- Hosts provide image URLs and stable intrinsic metadata through `FlutterImagePool` resolver callbacks, or provide decoded images directly to lower-level render and export APIs.
- Optional `ImageProvider` helpers are available from `canvas_renderer_flutter_image_providers.dart` for apps that want to convert common string refs into Flutter image providers.
- `CanvasRenderer` borrows text and image resources; it does not own or dispose them.
- `CanvasDocumentExporter` borrows its text pipeline and resolved input images; it does not own or dispose them.
- `FlutterTextPipeline` owns its cached Flutter text resources and must be disposed by its creator.
- `FlutterImagePool` owns its decoded raster handles and must be scoped to one rendering surface or operation.
- Gestures, selection, undo, editor state, and application workflows belong in an editor or app layer.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).

Copyright 2026 Nijify.
