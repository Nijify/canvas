# canvas_core

`canvas_core` is a pure-Dart canvas document engine. It provides a serializable
scene graph, platform-neutral document/render geometry, deterministic scene
computation, viewport math, and derived geometry.

Use it when you want to model or transform canvas-style documents without depending on Flutter, `dart:ui`, widgets, files, HTTP, or a specific rendering backend.

## Features

- `CanvasSceneDocument` and `Node` models for text, image, icon, path, and group content.
- Stable JSON serialization for storing, syncing, and round-tripping scene documents.
- `computeScene` for deterministic transforms, draw order, bounds, and cached geometry.
- `evaluateScene` for the prepared scene, computed geometry, and optional content bounds.
- Renderer-neutral geometry and viewport calculation shared by runtime consumers.
- Host-service contracts for text measurement, image intrinsics, image source resolution, and icon resolution.
- Generic scene font-family discovery for renderer/resource preflight.

## Graphics semantics and SVG

The typed scene and JSON round-trip are the current editable document contract.
The direction is to simplify `canvas_core` graphics semantics incrementally.
Familiar node names do not by themselves mean that a fill, transform, or effect
has SVG semantics. Changes should prefer established graphics meanings where
they fit, and document any deliberate difference and its cost across renderers
and editors.

The sibling [`canvas_svg_export`](../canvas_svg_export/README.md) package is a
strict, one-way check of prepared visual scenes. It uses the scene and
`ComputedScene`, reports unsupported semantics, and currently exports only a
small path profile. This does not make SVG the editable format.

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

Import the runtime API for documents, geometry, services, scene computation, and evaluation:

```dart
import 'package:canvas_core/canvas_core_runtime.dart';
```

Do not import files under `package:canvas_core/src/`; use `canvas_core_runtime.dart`.

## Basic usage

Create a document, compute it with host services, and evaluate it for Flutter painting or SVG export:

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
final evaluation = evaluateScene(document, services);
final computed = evaluation.computed;
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

## File-reference migration (Unreleased)

`parseCanvasAssetRef()` classifies reference syntax without interpreting files
for an operating system. `CanvasFileAssetRef.path` has been removed. Use `raw`
for the original trimmed reference and `uri` for parsed file-URI syntax; `uri`
is null for a path-like string.

```dart
final ref = parseCanvasAssetRef('file:///tmp/a%20b.png') as CanvasFileAssetRef;
// ref.raw and ref.canonicalKey == 'file:///tmp/a%20b.png'
// ref.uri == Uri.parse('file:///tmp/a%20b.png')
```

Native hosts that need a filesystem path must convert the URI in their own
adapter using the target platform's rules and handle conversion errors. Flutter
consumers can pass `ref.raw` to `sourceToProvider()` from
`canvas_renderer_flutter_image_providers.dart`; its native adapter performs
that conversion. Unsupported hosts must resolve file references to a supported
runtime source instead.

`canonicalKey` now equals `raw`: an escaped file URI and its decoded native path
are distinct logical keys. Review host caches that previously relied on their
implicit equivalence. This change does not rewrite persisted `sourceRef` values
or require a scene-format migration. Custom schemes remain host-owned.

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
  -> evaluateScene(preparedScene, services)
  -> SceneEvaluation
  -> Flutter renderer paints scene + computed geometry
```

`ScenePreparer` is a synchronous, renderer-neutral transformation applied by
the host before building:

```dart
final services = CoreServices(
  textMeasurer: myTextMeasurer,
  images: myImageIntrinsics,
  icons: myIconResolver,
);

final preparedScene =
    scenePreparer?.call(document, services) ?? document;

final evaluation = evaluateScene(preparedScene, services);
```

`evaluateScene` does not invoke preparation automatically. Pass the same
`CoreServices` instance to preparation and evaluation so both use the same
host capabilities. The Flutter renderer uses the evaluation's computed draw
order, transforms, and cached geometry to paint the prepared scene.

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
