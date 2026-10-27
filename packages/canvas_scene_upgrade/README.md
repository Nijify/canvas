# canvas_scene_upgrade

Optional, explicit JSON upgrades for persisted Canvas documents. Normal
`canvas_core` loading and rendering depend only on the current scene format.

## Usage

```dart
import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_scene_upgrade/canvas_scene_upgrade.dart';

final upgradedJson = upgradeCanvasScene(historicalJson);
final scene = decodeCanvasScene(upgradedJson);
```

The current target is scene v5. Supported versioned inputs are v1, v2, v3, v4,
and already-current v5. Earlier versions follow v1 -> v2 -> v3 -> v4 -> v5.
The input is never mutated. Already-current input is validated and returned in
a new top-level map; encoding defaults or normalizing the document is left to
`encodeCanvasScene`.

### Identified unversioned input

The only supported unversioned format is the `canvas_core` 0.10.x wire shape.
The caller must identify it explicitly; missing metadata does not identify an
arbitrary old document.

```dart
final upgradedJson = upgradeCanvasScene(
  knownCanvas010Json,
  legacyUnversioned: true,
  resolveLegacyIconWasGlyph: (iconRef) => historicalIconKinds[iconRef],
);
```

For icons with nonzero legacy shadows, the callback returns true for a font
glyph, false for a path, or null when unknown. Ambiguous cases are rejected.
The callback is unnecessary when those legacy shadows are zero. Unsupported
pre-0.10 image representations and mixed-format input are rejected.

## Guarantees and limits

- Historical steps validate their wire formats independently of current core.
  Only the completed result passes through the current decoder and integrity
  validation. Malformed wire data throws `FormatException`; invalid current
  runtime values throw `ArgumentError`. Diagnostic text is not a stable API.
- IDs, transforms, appearance, and unrelated authored metadata are retained
  according to each historical conversion. Output represents normalized
  geometry rather than obsolete shape-generator parameters.
- This is a document-format upgrade, not historical resource recovery or a
  pixel-identical rendering guarantee. Retired glyph/style icon resources must
  be replaced by the host's current vector resources.
- Quadratic-to-cubic conversion preserves curves, but conservative control-hull
  bounds can change center-derived pivots and resulting placement. There is no
  historical layout compensation. SVG path parsing/writing retains the current
  codec's documented floating-point limitations.
- The package upgrades plain Canvas scenes. Applications own tokenized wrappers,
  database changes, backups, and explicit adoption of the upgraded document.

## Package boundary

`canvas_scene_upgrade` depends on public `canvas_core` APIs. Core never imports
or re-exports the upgrade package. Intermediate converters and frozen historical
validators are internal; `upgradeCanvasScene` is the sole public entry point.

For callers moving from core's former upgrade exports, add this package and
import `package:canvas_scene_upgrade/canvas_scene_upgrade.dart`.
Replace direct `convertCanvasSceneV3ToV4(json)` calls with
`upgradeCanvasScene(json)`.

The v4 -> v5 step bakes historical TRS and pivots into complete affine matrices.
Geometry remains in its existing local coordinates. Translation-only transforms
need no measurements. Rotated/scaled group center pivots may need text metrics
and contain-fit image intrinsics: pass the original resource bundle as
`services: CoreServices(...)`. Missing required metrics fail explicitly. Hidden
center pivots use zero because v4 did not evaluate hidden layout; revealing them
later does not recover a historical auto-pivot. Custom pivots are baked directly.
This is an optional recovery tool; applications explicitly adopt or reject its
result. It is never a runtime read fallback.

## Verification

From the repository workspace, run `flutter pub get`, then run `dart analyze`
and `dart test` in `packages/canvas_scene_upgrade`. The upgrade suite covers
historical chains, geometry conversion, nonmutation, current-format rejection,
legacy ambiguity, frozen gradient validation, and package boundaries.
