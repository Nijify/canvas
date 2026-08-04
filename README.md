# Canvas for Dart and Flutter

[![canvas_core](https://img.shields.io/pub/v/canvas_core.svg?label=canvas_core)](https://pub.dev/packages/canvas_core)
[![canvas_renderer_flutter](https://img.shields.io/pub/v/canvas_renderer_flutter.svg?label=canvas_renderer_flutter)](https://pub.dev/packages/canvas_renderer_flutter)
[![canvas_editor_flutter](https://img.shields.io/pub/v/canvas_editor_flutter.svg?label=canvas_editor_flutter)](https://pub.dev/packages/canvas_editor_flutter)

A modular toolkit for building serializable 2D canvas documents, Flutter renderers, and visual editing experiences.

Use the complete stack or depend only on the packages your application needs.

## Packages

| Package | Purpose | Runtime |
|---|---|---|
| [`canvas_core`](packages/canvas_core) | Scene documents, geometry, layout, serialization, paint operations, hit testing, snapping, and history | Pure Dart |
| [`canvas_renderer_flutter`](packages/canvas_renderer_flutter) | Flutter drawing, text measurement, image management, and PNG export | Flutter |
| [`canvas_editor_flutter`](packages/canvas_editor_flutter) | Turnkey and composable visual editor UI | Flutter |

The dependency direction is one-way:

```text
canvas_editor_flutter
  -> canvas_renderer_flutter
      -> canvas_core
  -> canvas_core
```

`canvas_core` is independent of Flutter. The renderer implements Flutter-specific drawing, while the editor uses both packages to provide a complete editing experience.

## Installation

For document modeling and renderer-independent canvas logic:

```bash
dart pub add canvas_core
```

For Flutter rendering:

```bash
flutter pub add canvas_core canvas_renderer_flutter
```

For the complete Flutter editor:

```bash
flutter pub add canvas_core canvas_renderer_flutter canvas_editor_flutter
```

## Create a canvas document

```dart
import 'package:canvas_core/canvas_core_runtime.dart';

final document = CanvasSceneDocument(
  artboardSize: const Size2D(1080, 1080),
  backgroundFill: const CanvasFill.none(),
  backgroundOpacity: 1,
  children: <Node>[
    Node.text(
      id: 'headline',
      xf: const Transform2D(
        position: Vec2(540, 540),
      ),
      data: const TextData(
        text: 'Hello canvas',
        fontFamily: 'Inter',
        fontWeight: 700,
        fontSize: 72,
      ),
    ),
  ],
);
```

Canvas documents support JSON round-tripping:

```dart
final json = document.toJson();
final restored = CanvasSceneDocument.fromJson(json);
```

See the [`canvas_core` README](packages/canvas_core/README.md) for scene computation, paint operations, serialization, and interaction utilities.

## Render with Flutter

Use the same `FlutterTextPipeline` for core text measurement and Flutter painting:

```dart
import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';

final textPipeline = FlutterTextPipeline();

try {
  final renderPipeline = CanvasRenderPipeline(
    textMeasurer: textPipeline,
  );

  final snapshot = renderPipeline.build(document);

  final renderer = CanvasRenderer(
    text: textPipeline,
  );

  renderer.replay(canvas, snapshot.ops);
} finally {
  textPipeline.dispose();
}
```

The creator owns and disposes `FlutterTextPipeline`. Renderers and exporters only borrow supplied pipelines.

See the [`canvas_renderer_flutter` README](packages/canvas_renderer_flutter/README.md) for image loading, resource ownership, and PNG export.

## Use the Flutter editor

Provide a scene and application-owned runtime resources:

```dart
import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/canvas_editor_flutter.dart';

CanvasSceneEditor(
  initialScene: document,
  resources: resources,
  onSceneChanged: (updatedDocument) {
    persistDocument(updatedDocument);
  },
)
```

The editor includes selection, transforms, viewport controls, layers, inspector UI, history, shortcuts, and extensible asset and export capabilities.

See the [`canvas_editor_flutter` README](packages/canvas_editor_flutter/README.md) for runtime resources, editor lifecycle, extensions, image import, asset libraries, and export configuration.

## Documentation

| Package | Documentation |
|---|---|
| `canvas_core` | [README](packages/canvas_core/README.md) |
| `canvas_renderer_flutter` | [README](packages/canvas_renderer_flutter/README.md) |
| `canvas_editor_flutter` | [README](packages/canvas_editor_flutter/README.md) |

## License

Each package is licensed under the Apache License, Version 2.0:

- [`canvas_core`](packages/canvas_core/LICENSE)
- [`canvas_renderer_flutter`](packages/canvas_renderer_flutter/LICENSE)
- [`canvas_editor_flutter`](packages/canvas_editor_flutter/LICENSE)

Copyright 2026 Nijify.
