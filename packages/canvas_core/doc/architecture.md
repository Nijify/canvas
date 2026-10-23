# canvas_core architecture

`canvas_core` is a pure-Dart canvas document engine. It owns the runtime scene
model, document/render geometry primitives, deterministic scene computation,
viewport math, serialization, and logical resource contracts.

The package is complete on its own: apps can create `CanvasSceneDocument` values, serialize them, compute scene geometry, and layer editor interactions over the same runtime data without any product-specific package.

## Public entrypoints

Runtime API:

```dart
import 'package:canvas_core/canvas_core_runtime.dart';
```

Public consumers should not import `package:canvas_core/src/**`.

## Runtime pipeline

`evaluateScene` computes deterministic scene geometry and optional content bounds from an already-prepared scene and caller-supplied `CoreServices`.

```text
CanvasSceneDocument
  -> optional host-invoked ScenePreparer
  -> evaluateScene(preparedScene, services)
  -> SceneEvaluation
  -> Flutter scene painting
```

Hosts construct a stable `CoreServices` bundle and pass the same instance to a `ScenePreparer` and `evaluateScene`.

Scene evaluation does not invoke preparation itself. High-level renderer/editor layers decide where preparation belongs. In particular, an authoritative final-output renderer may own the preparation call so callers cannot accidentally render an already-prepared scene twice.

## Host services and logical resources

Core stays platform-neutral. `CoreServices` exposes synchronous capabilities needed during scene computation:

- `TextMeasurer textMeasurer`
- optional `ImageIntrinsics images`
- optional `IconResolver icons`

`ImageIntrinsics` is synchronous lookup only. Resource loading, retries, caches, and notifications belong outside core.

`CanvasImageAssetResolver` is a separate asynchronous host boundary for logical canvas image resources:

```text
logical sourceRef
  -> CanvasImageAssetResolver
  -> host-renderable runtime source
```

Resolver inputs are opaque logical `sourceRef` values stored in the document. `resolveSources()` results may be temporary or rotating runtime values such as signed URLs or blob URLs and must not be treated as persistent identity. `resolveIntrinsicSizes()` provides stable layout-affecting metadata keyed by the logical ref. Both result maps may be partial.

`collectSceneFontFamilies()` discovers logical font-family dependencies from
nested and hidden text plus caller-supplied fallbacks. Icons contribute no fonts.
Discovery does not load or validate fonts.

## Vector icons and compiled geometry

`IconResolver` returns one concrete `ResolvedIcon`: immutable normalized
source commands, an explicit finite positive viewBox, and a fill rule.
The resource requires a validated immutable `PathIR`; hosts prepare geometry before
construction and prepare resources before synchronous lookup.
Empty geometry is valid. All nonempty icon geometry is used as a filled path,
with the usual implicit closure of open contours and the declared fill rule.

`ComputedScene.iconById` contains one `ComputedIcon` per resolved instance:
source-space `PathIR`, `sourceToLocal`, and fill rule. The transform centers
the declared viewBox with uniform `min(sizePx / width, sizePx / height)` scale.
Painting consumes this evaluated result without resolver calls. The nominal
layout square remains stable and does not clip the fitted geometry.
Instance sizes are checked before layout and lookup, including when the
resolver is absent or the reference is unresolved.

Foreground gradients and shadow offsets/blur use node-local coordinates after
source fitting. Source-derived shadows remain independent of foreground color,
alpha, and visibility. Node/group transforms apply to the whole result.
Intrinsic outlines and multiple source paints are outside this icon contract.

`PathIR` is immutable geometry only; `localBounds()` estimates its geometry
from endpoints and curve controls. `PathData.source` owns geometry and
`PathData.appearance` owns fill and stroke. Layout uses geometry alone; visible
paint contributes separate bounds that conservatively include stroke caps and
joins. Compilation is cached by source identity independently of appearance.

The [strict SVG exporter](../../canvas_svg_export/README.md) supports its
documented ordinary-path profile and explicitly rejects icon nodes.

## Serialization boundary

Scene format v4 retains the scene tree and authored appearance model. Paths have
one of seven geometry sources: rect, circle, ellipse, line, polyline, polygon,
or path. General paths persist as SVG d and hold one immutable PathIR snapshot.
Polyline/polygon sources freeze numeric points and persist SVG point strings.

The shared core SVG path codec delegates syntax, shorthand, quadratics, and arcs
to path_parsing. Its PathProxy collector produces absolute M/L/C/Z geometry and
normalizes drawing after close into explicit contours. No SVG/XML document or
CSS model is introduced. The exporter shares the path writer while owning XML
and supported-export policy. Hosts use the same codec for icon preparation.

PathIR validates command structure and finite geometry at construction. General
paths and icons reuse it directly, without independently editable raw text or
command copies during evaluation. Shape compilation remains cached by immutable
source identity independently of appearance. Basic shapes use local numeric
coordinates; existing transforms and host application placement are unchanged.

Persistence validates common scene wire structure, delegates exact geometry
structure and parsing to the source codec, then checks runtime integrity. Reads
and writes use v4 only. upgradeCanvasScene retains explicit JSON routes through
v1/v2/v3 to v4; intermediate steps validate historical wire formats independently
of the current runtime. Migration contains no retired runtime source classes.

Generated model serializers remain implementation-level primitives. Persistence
checks raw structure before decoding and runtime integrity on both boundaries.

## Editor boundary

Interactive concerns such as history, picking, path hit testing, snapping,
and selection behavior belong to `canvas_editor_flutter`.

The editor consumes renderer-neutral runtime data from `canvas_core` so
interaction remains aligned with the same document geometry used for rendering,
without making editor-owned interaction geometry part of the core runtime contract.

## Package boundaries

- `canvas_core` is Dart-only and does not import Flutter, `dart:ui`, widgets, files, HTTP, or renderer-specific APIs.
- Runtime APIs operate on `CanvasSceneDocument`, `Node`, and renderer-neutral value types.
- Core owns logical resource contracts but does not load platform resources.
- Flutter painting consumes the prepared scene and `ComputedScene` draw order, transforms, and cached geometry.
- Apps/editors own when to resolve host data, prepare scenes, and invoke final rendering.

## Data flows

General rendering:

```text
Host/app data
  -> CanvasSceneDocument
  -> optional ScenePreparer with services
  -> evaluateScene(preparedScene, services)
  -> SceneEvaluation
  -> renderer
```

Editor consumption:

```text
CanvasSceneDocument + ComputedScene
-> canvas_editor_flutter interaction/runtime
-> updated CanvasSceneDocument
-> computeScene(...)
```

The editor consumes core document/render geometry and derives its own
interaction geometry from those canonical results. This keeps picking,
selection, snapping, and manipulation aligned with rendering without making
editor-only geometry part of the core runtime contract.
