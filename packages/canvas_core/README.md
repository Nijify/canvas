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
strict, one-way check of prepared visual scenes. It consumes one `SceneEvaluation`, reports unsupported semantics, and currently exports only a
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
      xf: Affine2D.translation(540, 540),
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

Use `collectSceneFontFamilies` to collect text and fallback font families,
including hidden and nested scene content:

```dart
final fontFamilies = collectSceneFontFamilies(
  document,
  fallbackFontFamilies: fallbackFontFamilies,
);
```

Icons are filled vector symbols. An `IconResolver` returns a `ResolvedIcon`
with validated immutable `PathIR` geometry, a finite positive `viewBox`, and a
`FillRule`. Hosts parse SVG path data through `parseSvgPathData()` before constructing the resource.
The geometry has no font or source paint and is reused during evaluation.
The instance's `CanvasAppearance` supplies its foreground and shadows.

Scene evaluation fits the declared viewBox uniformly into the centered
`sizePx × sizePx` layout square. Source margins are preserved. Non-square
artwork is centered without stretching, and the square does not clip paint.
Instance sizes must be finite and positive, including for unresolved icons.

## File references

`parseCanvasAssetRef()` classifies reference syntax without interpreting files
for an operating system. `CanvasFileAssetRef.raw` contains the original trimmed
reference, and `uri` contains parsed file-URI syntax. For a path-like string,
`uri` is null.

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

`canonicalKey` equals `raw`: an escaped file URI and its decoded native path
are distinct logical keys. Hosts own custom schemes.

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

Persistence uses scene format v5. For supported historical JSON, explicitly call
`upgradeCanvasScene()` from the optional
[`canvas_scene_upgrade`](../canvas_scene_upgrade) package before decoding. Both
persistence functions enforce scene integrity; `requireCanvasSceneIntegrity()` performs a standalone fail-fast
check. Malformed wire structure throws `FormatException`; runtime integrity
failures throw `ArgumentError`.

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

## SVG-aligned geometry

`PathNode` uses one of `RectSource`, `CircleSource`, `EllipseSource`, `LineSource`,
`PolylineSource`, `PolygonSource`, or `GeneralPathSource`. Rectangles use numeric
local x/y/width/height with optional rx/ry. Circle/ellipse centers default to zero.
Dimensions and radii are nonnegative; zero dimensions/radii disable basic shapes.

```dart
final rectangle = RectSource(x: -80, y: -50, width: 160, height: 100, rx: 12);
final arbitrary = GeneralPathSource.fromSvg('M0 0Q30 60 60 0Z');
final resource = ResolvedIcon(
  pathIR: parseSvgPathData('M0 0L24 0L12 24Z'),
  viewBox: const Rect2D(0, 0, 24, 24),
  fillRule: FillRule.nonZero,
);
```

General paths write `{"kind":"path","d":"..."}`. Points write SVG numeric strings.
Runtime geometry uses validated immutable absolute move/line/cubic/close commands.
The shared codec handles path data, not complete SVG documents, CSS, or percentage
lengths. Coordinate spelling is canonicalized; parsing and arc conversion use
floating-point arithmetic and arc approximation. Source coordinates are retained
without implicit centering. Existing transforms and host application placement
remain separate from geometry.

The `path_parsing` dependency currently limits explicit exponents to -37 through
38; the writer expands its own output outside that exponent range.
Nonfinite/unsupported numeric input fails with `FormatException`; original
SVG spelling and bit-exact decimal save/load round trips are not preserved.
`writeSvgPathData` is deterministic for unchanged geometry and does not round it.

Use `upgradeCanvasScene()` from the optional `canvas_scene_upgrade` package for
v3 input and the retained historical routes. Migration does not restore
star-generation parameters or compensate for quadratic control-hull/pivot changes. Historical underline bars
become rectangles; new Line actions create stroke-based geometry.

## Affine transforms (scene v5)

A node owns a complete immutable local-to-parent `Affine2D`. JSON stores
`xf: [a,b,c,d,e,f]`; omitted xf is identity. `A * B` applies B before A.
Use `Affine2D.translation`, `.rotation`, `.scale`, or `.shear` to compose an
explicit mapping. `affineAround(anchor, delta)` is a temporary edit operation,
not persisted pivot state. Bounds and resources never change node transforms.

SceneTreeOps deltas name local, parent, or world space. Reparenting requires
`TransformPreservation.local` or `.world`. Operations needing a parent inverse
fail when it is singular or poorly conditioned. `tryInverse()` exposes that
failure without inventing a fallback. Renderer buffers returned by
`toColumnMajor4x4()` are copies.
