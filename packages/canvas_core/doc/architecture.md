# canvas_core architecture

`canvas_core` is a pure-Dart canvas document engine. It owns the runtime scene model, geometry primitives, deterministic scene computation, hit testing, snapping, viewport math, and renderer-agnostic paint operations.

The package is complete on its own: apps can create `CanvasSceneDocument` values, serialize them, compute scene geometry, build paint operations, and layer editor interactions over the same runtime data without any product-specific package.

## Public entrypoints

Use the public barrels from `lib/`:

### Runtime API

```dart
import 'package:canvas_core/canvas_core_runtime.dart';
```

Use this for document creation, serialization, scene computation, paint operation generation, geometry, content bounds, viewport math, and host service contracts.

The canonical runtime flow is:

```text
CanvasSceneDocument
  -> computeScene(scene, services)
  -> buildPaintOpsFromScene(scene, computed)
  -> renderer-specific PaintOp replay
```

### Headless editor utilities

```dart
import 'package:canvas_core/canvas_core_editor.dart';
```

Use this when you need interaction mechanics over runtime scenes, including history, hit testing, picking, and snapping. These helpers consume `ComputedScene` so interactive behavior matches rendered output.

## Package boundaries

- `canvas_core` is Dart-only and does not import Flutter, `dart:ui`, widgets, files, HTTP, or renderer-specific APIs.
- Runtime APIs operate on `CanvasSceneDocument` and `Node` values.
- Host apps provide text measurement, image intrinsic sizes, and icon resolution through service interfaces.
- Renderers consume `PaintOp` values instead of reimplementing scene traversal, transforms, layout, or z-order.
- Public consumers should import only `canvas_core_runtime.dart` and, when needed, `canvas_core_editor.dart`; do not import `package:canvas_core/src/**`.

## Runtime data flow

```text
Host/app data
  -> CanvasSceneDocument
  -> CoreServices
  -> computeScene(...)
  -> ComputedScene
  -> buildPaintOpsFromScene(...)
  -> PaintOp list
  -> renderer
```

## Interaction data flow

```text
CanvasSceneDocument + ComputedScene
  -> pickTopAtScene / snapScene / History
  -> updated CanvasSceneDocument
  -> computeScene(...)
```

Keeping rendering and interaction on the same computed snapshot prevents drift between what users see and what the editor can select, snap, or export.
