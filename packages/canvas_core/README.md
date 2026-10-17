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

Path layout bounds describe geometry independently of appearance, including
horizontal and vertical lines. Stroke edits expand paint bounds for content
fitting without changing pivots, selection geometry, or snapping. Paint bounds
account conservatively for square caps and miter joins; raster padding remains
separate. Invisible foregrounds and strokes retain their authored settings
without contributing paint bounds. Text/icon source underlays remain
independent of foreground visibility.

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
with a normalized `CommandPathSource`, a finite positive `viewBox`, and a
`FillRule`. Hosts normalize geometry before constructing the resource.
The command source is immutable and has no font or source paint.
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

`encodeCanvasScene` writes scene format v3; `decodeCanvasScene` accepts v3.
Reading checks raw wire structure before decoding, then enforces runtime
integrity. Writing checks runtime integrity before recursive serialization;
package serializers emit the canonical wire structure without another scan.
Malformed wire data throws `FormatException`; integrity failures throw
`ArgumentError`. Error messages provide context without stable diagnostic codes,
paths, or ordering guarantees.

Call `requireCanvasSceneIntegrity(document)` before independently usable
operations that recurse through a scene or begin resource work. It rejects the
first failure and checks numeric values, appearance, identities, asset references,
JSON payloads, cycles, and node discriminator consistency. Component availability
and export capabilities remain separate caller concerns.

| Boundary | Responsibility |
| --- | --- |
| Read | Wire checks → decode → runtime integrity |
| Write | Runtime integrity → canonical encoding |
| PNG | Integrity before resources/preparation; check output when a preparer runs |
| SVG | Integrity, then supported export capabilities |

Checks around an actual transformation are necessary even if the same guard
already ran on its input. Avoid repeating a check on unchanged data within one
operation; independently usable entry points still enforce their prerequisites.

See the [scene-v3 upgrade guide](doc/migration-v3.md) for compatible package
versions, Dart model changes, explicit persistence migration, and editor fields.

Paths require a `source` and persist fill/stroke through `appearance`.
`stroke: null` means no configuration; transparent and zero-width stroke
configurations retain their settings. Dash arrays are preserved, including
zeros and odd-length sequences, but are not yet rendered as dashes. Stroke
miter limits must be finite and at least 1. Negative source dimensions/radii
and nonpositive icon sizes are invalid; zero-sized path geometry is allowed.

Upgrade historical JSON explicitly before decoding:

```dart
final restored = decodeCanvasScene(upgradeCanvasScene(historicalJson));
```

The public upgrader supports v2, v1 through v2, and explicitly identified
unversioned `canvas_core` 0.10.x through the existing migration chain. Only that
known unversioned format uses `legacyUnversioned: true`, with
`resolveLegacyIconWasGlyph` when historical icon shadows require it. Missing
version metadata does not select a historical format automatically.

The v2 conversion prefers a non-null `source` over obsolete `points`, preserves
points-only contour breaks, and uses explicit empty commands for empty fallback
geometry. It combines fill/stroke fields into appearance, preserving dash
metadata and nondefault inactive stroke settings. Unsupported or malformed
input fails explicitly. Migration preserves content where practical without
reproducing every historical rendering or editor behavior.

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
