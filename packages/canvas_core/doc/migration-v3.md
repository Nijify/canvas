# Upgrade to scene v3 and shared path appearance

Use these compatible package versions together:

| Package | Version |
| --- | --- |
| `canvas_core` | `0.16.x` |
| `canvas_renderer_flutter` | `0.15.x` |
| `canvas_editor_flutter` | `0.19.x` |
| `canvas_svg_export` (experimental) | `0.3.x` |

The package versions and persisted `sceneFormatVersion` are separate. This
release reads and writes scene format **3** through the persistence boundary.

## Dart model changes

`PathData` has one required geometry source, a fill rule, and shared appearance:

```dart
import 'package:canvas_core/canvas_core_runtime.dart';

final path = PathData(
  source: const RectSource(160, 100),
  fillRule: FillRule.evenOdd,
  appearance: CanvasAppearance(
    foreground: const CanvasFill.solid(0xFF22C55E),
    stroke: CanvasStroke(color: 0xFF111111, width: 2),
  ),
);
```

| Previous path member | Current location |
| --- | --- |
| `points` | `source: PolylineSource(points)` |
| Optional `source` | Required `source`; use `CommandPathSource([])` for empty geometry |
| `fill` | `appearance.foreground` |
| `strokeColor`, `strokeWidth` | `appearance.stroke.color`, `.width` |
| `strokeCap`, `strokeJoin` | `appearance.stroke.cap`, `.join` |
| `miterLimit`, `dash` | `appearance.stroke.miterLimit`, `.dash` |
| `fillRule` | Remains on `PathData` |

Construct a `CanvasStroke` when a stroke is configured. Its defaults are width
4, butt cap, miter join, miter limit 4, and an empty dash list. Null means no
configured stroke. Transparent colors and zero width keep the configuration
available for subsequent edits. Dash values must be finite and nonnegative;
zero entries and odd-length sequences are retained as authored.

`CanvasStroke` is no longer `const`: its constructor snapshots the supplied
dash list into owned, unmodifiable storage. Generated `copyWith` and JSON
decoding use that constructor too. Mutating a list after passing it to a stroke
or a copy cannot change an existing document, equality/hash value, or undo/redo
entry. Remove `const` from stroke construction and enclosing constant
expressions; unrelated constant geometry and fills can remain constant.

Paths default to no foreground and no configured stroke. Text and icons keep
their dark foreground default. Paths support strokes; text and icons support
source underlays. Unsupported combinations fail validation.

`PolylineSource` snapshots its point list and is no longer `const`. Null points
continue to separate contours. Appearance edits reuse compiled geometry when
the source object is unchanged.

## Persisted JSON

At an explicit migration boundary, upgrade existing v2 JSON and persist the
successfully decoded v3 result using the application's storage:

```dart
final upgradedJson = upgradeCanvasScene(storedJson);
final scene = decodeCanvasScene(upgradedJson);
final jsonToPersist = encodeCanvasScene(scene);
```

Subsequent ordinary v3 reads use `decodeCanvasScene()` directly. Changing only
the version number does not migrate obsolete path fields.

The v2 migration selects a non-null source before considering old points,
preserves contour breaks, and combines fill/stroke fields into appearance.
Only the default unconfigured historical stroke becomes null; nondefault
inactive settings and dash metadata remain stored. Conversion validates the
result and leaves the input JSON unmodified.

Public migration routes also retain v1 and the explicitly identified
unversioned canvas_core 0.10.x format. The latter requires
`legacyUnversioned: true`; its existing `resolveLegacyIconWasGlyph` requirement
still applies when an icon has a nonzero historical shadow offset.

Use `encodeCanvasScene()` and `decodeCanvasScene()` for persisted documents.
Decoding checks raw structure before constructing and checking the runtime
scene. Encoding checks integrity before recursive canonical serialization,
including cycles and contradictory generated node labels, without rescanning the
output. Malformed raw data throws `FormatException`; invalid runtime semantics
throw `ArgumentError`. Generated model methods remain implementation primitives.

### Integrity API changes

Replace `validateCanvasSceneDocument()` calls with
`requireCanvasSceneIntegrity(scene)`. Success returns normally; the first failure
throws `ArgumentError`. The collect-all issue type and enum and
`CanvasSceneFormatException` are removed. Error messages remain useful context,
with no stable diagnostic-code, path, or ordering contract. Historical import
routes are unchanged; conversion can reject malformed data with ordinary errors.

The guard validates generic scene data. Keep component availability and export
capability checks separate. Check before recursive work or side effects, and
check transformed output when a preparer or other transformation runs.

Converter exports are deliberate: `Vec2Converter`, `NullableVec2Converter`,
`Size2DConverter`, and `NullableSize2DConverter` remain available for host-owned
models. `LinearGradientSpecConverter` is removed; `CanvasFillConverter`,
`PathSourceConverter`, and `estimatePathPaintBounds` are implementation details
and are no longer exported from the runtime entry point.

## Bounds and interaction

Path layout uses geometry alone, including horizontal and vertical lines with
zero height or width. Visible foreground and strokes contribute paint bounds;
empty and move-only paths have no paint bounds. Configured transparent or
zero-width strokes remain authored data.

Stroke paint estimates conservatively include caps and joins and may include
unused space. Raster padding remains separate. Content fitting and group pivots
can differ from earlier stroke-expanded layout; historical padding and pixels
are not exact compatibility guarantees.

Stroke edits preserve layout, pivots, selection handles, and snapping. Picking
uses geometry independently of paint visibility, with a zoom-aware minimum
outline tolerance for unfilled and open paths.

## Editor fields

`CanvasFields.pathFill` edits `appearance.foreground`. The new aggregate
`CanvasFields.pathStroke` has type `CanvasStroke?`; use a nullable type argument
with `getField()`, `commitField()`, and `updateField()`. Clear a configuration by
committing null. Functional updates receive the latest canonical value and
preserve unrelated properties through `copyWith()`.

`FieldCodec` readers, fallbacks, and writer values accept `Object?`. Custom
writers that explicitly typed the value parameter as `Object` must widen it
to `Object?` and handle their field's concrete type. Existing non-null field
values keep their semantics.

The standard path inspector includes stroke controls. Custom inspectors can
reuse `StrokeEditor` from `canvas_editor_flutter/extensions.dart`. See
[path stroke authoring](../../canvas_editor_flutter/README.md#path-stroke-authoring)
for examples.

## Dash rendering and SVG

Flutter currently paints configured strokes solid, preserving dash metadata
for later edits. The strict SVG exporter rejects active nonempty dash lists
with `unsupportedDashedStroke`; invisible or zero-width strokes do not trigger
that issue. The inspector therefore offers no dash authoring controls.

Follow [VERSIONING.md](../VERSIONING.md) for package checks and publishing dry
runs after local validation.
