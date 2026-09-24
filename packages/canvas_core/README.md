# canvas_core

`canvas_core` is a pure-Dart canvas document engine. It provides a serializable
scene graph, platform-neutral document/render geometry, deterministic scene
computation, viewport math, and renderer-agnostic paint operations.

Use it when you want to model or transform canvas-style documents without depending on Flutter, `dart:ui`, widgets, files, HTTP, or a specific rendering backend.

## Features

- `CanvasSceneDocument` and `Node` models for text, image, icon, path, and group content.
- Stable JSON serialization for storing, syncing, and round-tripping scene documents.
- `computeScene` for deterministic transforms, draw order, bounds, and cached geometry.
- `buildPaintOpsFromScene` for a renderer-neutral draw plan.
- Renderer-neutral geometry and viewport calculation shared by runtime consumers.
- Host-service contracts for text measurement, image intrinsics, image source resolution, and icon resolution.
- Generic scene font-family discovery for renderer/resource preflight.

## Installation

Add the package to your app or package:

```bash
dart pub add canvas_core
```

For Flutter projects:

```bash
flutter pub add canvas_core
```

## Imports

Import the runtime API for documents, geometry, services, scene computation, and paint operations:

```dart
import 'package:canvas_core/canvas_core_runtime.dart';
```

Do not import files under `package:canvas_core/src/`; use `canvas_core_runtime.dart`.

## Basic usage

Create a document, compute it with host services, and build paint operations for any renderer:

```dart
import 'package:canvas_core/canvas_core_runtime.dart';

final document = CanvasSceneDocument(
  artboardSize: const Size2D(1080, 1080), 
  backgroundFill: const CanvasFill.none(),
  backgroundOpacity: 1.0,
  children: <Node>[
    Node.text(
      id: 'headline',
      xf: const Transform2D(position: Vec2(540, 540)),
      data: const TextData(
        text: 'Hello canvas',
        fontFamily: 'Inter',
        fontWeight: 700,
        fontSize: 72,
      ),
    ),
  ],
);

final services = CoreServices(textMeasurer: myTextMeasurer);
final computed = computeScene(document, services);
final paintOps = buildPaintOpsFromScene(document, computed);
```

`myTextMeasurer` is supplied by your runtime. A Flutter app can use
`FlutterTextPipeline` from `canvas_renderer_flutter`; a server or CLI can
implement `TextMeasurer` directly.

## Runtime resource discovery

Core discovers logical resource requirements without loading platform resources.

Use `collectSceneFontFamilies` to collect text and font-backed icon families,
including hidden and nested scene content:

```dart
final fontFamilies = collectSceneFontFamilies(
  document,
  fallbackFontFamilies: fallbackFontFamilies,
  icons: myIconResolver,
);
```

## Immutable node editing

`NodeEditingX` provides common immutable field edits that preserve node
identity and tree structure:

```dart
final renamed = node.withName('Headline');
final moved = renamed.withXf(nextTransform);
final hidden = moved.withHidden(true);
```

Use `SceneTreeOps` for structural operations such as adding, deleting, moving,
duplicating, or reordering scene nodes.

## JSON round-trip

```dart
final json = encodeCanvasScene(document);
final restored = decodeCanvasScene(json);
```

## Rendering pipeline

The canonical runtime flow is:

```text
CanvasSceneDocument
  -> optional host-invoked ScenePreparer
  -> CanvasRenderPipeline.build()
  -> RenderSnapshot
  -> renderer-specific PaintOp replay
```

`ScenePreparer` is a synchronous, renderer-neutral transformation applied by
the host before building:

```dart
final renderPipeline = CanvasRenderPipeline(
  textMeasurer: myTextMeasurer,
  images: myImageIntrinsics,
  icons: myIconResolver,
);

final preparedScene =
    scenePreparer?.call(document, renderPipeline.services) ?? document;

final snapshot = renderPipeline.build(preparedScene);
```

`CanvasRenderPipeline` does not invoke preparation automatically. Its stable
`services` instance can be shared with preparation so preparation and final
layout use the same host services.

Renderers consume `PaintOp` values. They do not need to interpret the scene graph, layout rules, or z-order themselves.

## Architecture

See [doc/architecture.md](doc/architecture.md) for package entrypoints, data flow, and layering guidance.

## Versioning

`canvas_core` follows semantic versioning. While the package is below `1.0.0`, breaking changes are released as `0.(x+1).0`.

See [VERSIONING.md](VERSIONING.md) for the full policy.

## Package boundaries

- `canvas_core` is Dart-only and must stay independent of Flutter and `dart:ui`.
- Text measurement, image intrinsic sizes, and icon lookup are host services.
- Renderers and editors should reuse `ComputedScene` for canonical document transforms, local layout bounds, and paint bounds. Editor-only derived interaction geometry belongs to `canvas_editor_flutter`.
- Editor-specific interaction concerns such as history, picking, snapping, and selection belong to `canvas_editor_flutter`.
- Public core consumers should import `canvas_core_runtime.dart`.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).

Copyright 2026 Nijify.
