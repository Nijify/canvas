# canvas_core

`canvas_core` is a pure-Dart canvas document engine. It provides a serializable scene graph, platform-neutral geometry primitives, deterministic scene computation, hit testing, snapping, viewport math, and renderer-agnostic paint operations.

Use it when you want to model or transform canvas-style documents without depending on Flutter, `dart:ui`, widgets, files, HTTP, or a specific rendering backend.

## Features

- `CanvasSceneDocument` and `Node` models for text, image, icon, path, and group content.
- Stable JSON serialization for storing, syncing, and round-tripping scene documents.
- `computeScene` for deterministic transforms, draw order, bounds, and cached geometry.
- `buildPaintOpsFromScene` for a renderer-neutral draw plan.
- Headless editor helpers for hit testing, snapping, history, and viewport calculation.
- Host-service contracts for text measurement, image intrinsics, and icon resolution.

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

Import the editor utilities only when you need headless interaction helpers such as hit testing, snapping, or undo history:

```dart
import 'package:canvas_core/canvas_core_editor.dart';
```

Do not import files under `package:canvas_core/src/`; use the public barrels above.

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

final services = CoreServices(tm: myTextMeasurer);
final computed = computeScene(document, services);
final paintOps = buildPaintOpsFromScene(document, computed);
```

`myTextMeasurer` is supplied by your runtime. A Flutter app can use `FlutterTextMeasurer` from `canvas_renderer_flutter`; a server or CLI can implement `TextMeasurer` directly.

## JSON round-trip

```dart
final json = document.toJson();
final restored = CanvasSceneDocument.fromJson(json);
```

## Rendering pipeline

The canonical flow is:

```text
CanvasSceneDocument
  -> computeScene(scene, services)
  -> buildPaintOpsFromScene(scene, computed)
  -> renderer-specific PaintOp replay
```

Renderers consume `PaintOp` values. They do not need to interpret the scene graph, layout rules, or z-order themselves.

## Architecture

See [doc/architecture.md](doc/architecture.md) for package entrypoints, data flow, and layering guidance.

## Versioning

`canvas_core` follows semantic versioning. While the package is below `1.0.0`, breaking changes are released as `0.(x+1).0`.

See [VERSIONING.md](VERSIONING.md) for the full policy.

## Package boundaries

- `canvas_core` is Dart-only and must stay independent of Flutter and `dart:ui`.
- Text measurement, image intrinsic sizes, and icon lookup are host services.
- Paint, hit testing, snapping, selection, and export should reuse `ComputedScene` so they agree on transforms and bounds.
- Public consumers should import only `canvas_core_runtime.dart` and, when needed, `canvas_core_editor.dart`.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).

Copyright 2026 Nijify.
