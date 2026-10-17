## 0.16.0

- **Breaking:** require one `PathData.source` and move path fill/stroke fields
  into `CanvasAppearance`. Paths default to no foreground and no configured
  stroke. Add `CanvasStroke` with independent inactive settings.
- **Breaking:** `PolylineSource` snapshots its points and is no longer `const`.
  Cache compiled geometry by source identity independently of appearance and
  fill rule.
- **Breaking:** `CanvasStroke` snapshots supplied dash lists and is no longer
  `const`. Construction, `copyWith`, and JSON decoding retain owned,
  unmodifiable dash values so caller mutations cannot alter equality, hashes,
  current documents, or undo/redo history. Stroke defaults and wire data remain
  unchanged, including transparent/zero-width settings and odd or zero dashes.
- Add `CanvasFields.pathStroke` as the stable aggregate identity for an optional
  authored path stroke.
- **Breaking:** ordinary path layout bounds now use geometry alone. Stroke
  padding affects paint/content bounds independently of pivots and layout.
  Content fitting and group pivots can differ from earlier stroke-based layout.
- Estimate path paint bounds conservatively for square caps and miter joins;
  retain zero-area line layout while allowing visible strokes to add content.
  Empty/move-only paths and invisible foregrounds/strokes add no paint bounds.
- Expose `fillContributesToPaint`; transparent
  text/icon foregrounds no longer add bounds independently of their underlays.
- **Breaking:** write/read scene format v3 with required path sources and
  shared appearance. Reject obsolete path fields and unsupported appearance
  combinations rather than silently discarding them.
- Upgrade v2 paths explicitly through `upgradeCanvasScene`, retaining v1 and
  identified unversioned 0.10.x migrations and icon-resolution requirements.
  Preserve contour breaks, dash arrays, and nondefault inactive stroke data.
- **Breaking:** replace collect-all `validateCanvasSceneDocument`, its issue
  type/enum, and `CanvasSceneFormatException` with the shared fail-fast
  `requireCanvasSceneIntegrity` guard and ordinary errors. Diagnostic codes,
  paths, messages, and ordering are not stable API contracts.
- Check node labels against their variants before encoding, alongside runtime
  semantics and cycles; remove the redundant full output-wire scan. Keep strict
  raw-wire decoding and share command/gradient structure with their decoders.
- **Breaking:** remove the unused `LinearGradientSpecConverter`; stop exporting
  internal `CanvasFillConverter`, `PathSourceConverter`, and
  `estimatePathPaintBounds`. Keep geometry converter annotations public.
- Preserve path dimensions/radii and icon-size integrity checks, appearance
  defaults, inactive stroke settings, dash arrays, and historical import routes.
- Keep historical migration fixtures and update current contract fixtures to
  v3. Historical rendering/editor fidelity is practical rather than exact.
- Document model, persistence, bounds, and editor adoption in the
  [scene-v3 upgrade guide](doc/migration-v3.md).

## 0.15.0

- **Breaking:** replace `ResolvedIconText` and `ResolvedIconPath` with one
  filled-vector `ResolvedIcon`, requiring normalized `CommandPathSource`
  geometry, viewBox, and fill rule. Hosts prepare vector resources before
  synchronous lookup and remove icon-only font registration. Instance
  `CanvasAppearance` supplies foreground paint and shadows.
- **Breaking:** replace `ComputedScene.iconTextById` and `iconPathIRById` with
  `iconById`. Each `ComputedIcon` exposes source-space `pathIR`, the centered
  uniform viewBox fit in `sourceToLocal`, and `fillRule`.
- **Breaking:** remove `PathStyle`, `PathIR.style`, and style-bearing
  compilation. Use `PathIR(commands)`; `localBounds()` has no `includeStroke`
  argument and describes geometry only. Ordinary-path paint, fill rule, and
  stroke properties remain on `PathData`; evaluated bounds remain in the
  computed scene.
- **Breaking:** remove the `icons` argument from `collectSceneFontFamilies()`;
  it discovers text and supplied fallback families. Icons contribute no fonts.
- **Breaking:** remove `SvgPathSource`, whose compilation was unimplemented.
  Raw `kind: "svg"` sources now fail during decoding. Normalize SVG paths to a
  supported command source before loading.
- Scene JSON compatibility does not promise compatibility with retired icon
  resources or unchanged artwork, padding, and pixels. Hosts replace font/glyph
  and styled-path icon resources with the new vector definitions.
- Add immutable, geometry-only `CommandPathSource` with strict JSON decoding
  and direct compilation of absolute move/line/quadratic/cubic/close commands.
- Reject nonfinite or nonpositive icon sizes before layout and resource lookup,
  including when an icon resolver is absent or the reference is unresolved.
- **Breaking:** `PathIR` now snapshots its commands and exposes an unmodifiable
  list. Its constructor is no longer `const`.

## 0.14.0

- **Breaking:** replace `CanvasRenderPipeline`, `RenderSnapshot`, and the renderer-neutral `PaintOp` pipeline with `evaluateScene(preparedScene, services)` returning `SceneEvaluation`. The evaluated scene and `ComputedScene` geometry are now the inputs to rendering; `PathIR` remains available for computed path geometry.
- **Breaking:** adopt persisted scene format v2 and replace angle/width linear gradients with explicit target-local start/end points and ordered color stops. `decodeCanvasScene()` reads the current v2 format; use `upgradeCanvasScene()` to migrate supported v1 and identified 0.10.x unversioned scenes while preserving their previous gradient appearance.
- Share current linear-gradient semantic checks between strict v2 decoding and in-memory scene validation, including finite and distinct endpoints, stop counts, offset range/order, and ARGB colors. Equal stop offsets remain valid for hard transitions; historical migration rules are unchanged.

## 0.13.0

- **Breaking:** remove `CanvasFileAssetRef.path`. File references now expose the
  trimmed `raw` value and an optional unconverted `uri`; native path conversion
  belongs to the executing host.
- **Breaking:** file-reference `canonicalKey` now equals `raw`. A file URI and
  its converted native path no longer share an implicit cache key. Stored scene
  `sourceRef` values and the scene format are unchanged.
- **Breaking:** remove `CanvasFit` and `CanvasViewportPlanner`. `computeViewport()` now accepts one caller-selected `Rect2D sourceBounds` and returns a uniform `CanvasViewportTransform` with `scale` and translation only.
- Keep optional uniform scale clamping with recentering and `snapTranslation()`; callers now own artboard/content selection, padding, output sizing, and other viewport policy.

## 0.12.0

- **Breaking:** version persisted Canvas scene JSON with
  `sceneFormatVersion: 1`. `encodeCanvasScene()` now emits the current scene
  format version, while `decodeCanvasScene()` rejects missing, malformed, and
  unsupported versions.
- Add `upgradeCanvasScene()` for explicitly identified `canvas_core 0.10.x`
  unversioned scene JSON.
- Migrate legacy text and icon `fill` / `shadowOffset` data to
  `CanvasAppearance`, remove persisted node `locked` values, and preserve
  historical glyph-versus-path icon shadow behavior through caller-supplied
  icon rendering knowledge.
- Reject unsupported older image `sourcePath` payloads instead of allowing the
  current image decoder to silently discard their source.
- Keep `sceneFormatVersion` as persistence metadata outside the runtime
  `CanvasSceneDocument` model.

## 0.11.0

- **Breaking:** remove the optional `idGen` parameter from
  `SceneTreeOps.duplicateSubtree()` and remove `createdIds` from its result.
  Subtree duplication now generates deterministic copy-style node IDs while
  skipping IDs already used by the document or the new copy.
- Reject blank, duplicate, or colliding node IDs when adding subtrees, and
  guard structural `replaceById()` operations against invalid replacement IDs
  while preserving ordinary property updates and subtree moves.
- **Breaking:** remove persisted canvas-object locking from all `Node` variants
  and remove `NodeEditingX.withLocked()`. Encoded scenes no longer emit a
  `locked` field.
- **Breaking:** remove the built-in lock veto from scene-tree transform
  operations. Replace-transform, translate, rotate, and uniform scale now
  operate on any existing node.
- **Breaking:** replace `ComputedScene.localBoundsById` and
  `ComputedScene.visualBoundsWorldById` with explicit
  `layoutBoundsLocalById`, `paintBoundsLocalById`, and
  `paintBoundsWorldById` maps.
- **Breaking:** remove `ComputedScene.inverseWorldById`. Editor-owned inverse
  transforms and world layout bounds now live in `canvas_editor_flutter`.
- Separate stable layout geometry from paint-bound estimates so effects and
  content fitting can expand paint bounds without changing transform pivots,
  selection, snapping, or manipulation geometry.
- **Breaking:** replace `TextData.fill`, `TextData.shadowOffset`,
  `CanvasIconData.fill`, and `CanvasIconData.shadowOffset` with the shared
  `CanvasAppearance` model.
- Add ordered `CanvasSourceUnderlay` values with stable serialization and
  validation, including configurable shadow effects.
- Add `CanvasFields.textUnderlays` and `CanvasFields.iconUnderlays` as
  aggregate field identities for editing authored text and icon source
  underlays.
- Allow text and icons to use `CanvasFill.none()` as their foreground while
  retaining their source silhouette for underlay rendering.
- **Breaking:** remove `canvas_core_editor.dart`; editor-owned history, picking,
  path hit testing, and snapping now live in `canvas_editor_flutter`.
- **Breaking:** remove selection geometry and editor-only world interaction
  geometry from the core runtime API.
- Keep `canvas_core` focused on document/runtime semantics, document and render
  geometry, scene computation, serialization, and paint-plan construction.

## 0.10.0

- **Breaking:** replace the `NodeId` alias with the shared `ElementId` identity type.
- **Breaking:** make `TextMeasurer` and `ImageIntrinsics` interface-only runtime contracts and remove image-intrinsic change notifications from core.
- **Breaking:** rename `CoreServices.tm` to `textMeasurer` and remove the forwarding text-measurement extension.
- Add `CanvasImageAssetResolver` for batch resolution of logical image `sourceRef` values into host-renderable sources and stable intrinsic metadata.
- Add `collectSceneFontFamilies` for renderer/resource preflight across nested and hidden text and font-backed icon nodes.
- Keep renderer-neutral scene preparation outside `CanvasRenderPipeline`; the pipeline continues to own deterministic scene computation and paint-op construction only.

## 0.9.0

- **Breaking:** normalize image backing sources into the document-local
  `CanvasSceneDocument.assets` registry.
- **Breaking:** replace `ImageData.sourcePath` with nullable `assetId` and make
  `ImageData.size` a required editable frame size.
- Add `CanvasImageAsset` with an opaque `sourceRef` and optional persisted
  intrinsic dimensions.
- Validate image asset records and image-to-asset references.

## 0.8.2

- Add `encodeCanvasScene` and `decodeCanvasScene` as the canonical external
  JSON boundary for `CanvasSceneDocument` values.
- Keep scene decoding separate from semantic document validation.

## 0.8.1

- Add deterministic, domain-neutral `CanvasSceneDocument` validation with
  stable machine-readable issue codes and JSON Pointer paths.
- Validate generic scene integrity including finite numeric values, established
  ranges, globally unique node IDs, neutral group-behavior envelopes, and
  recursively JSON-safe behavior data.
- Keep unknown group behavior types and versions valid so optional extension
  packages remain responsible for component semantics.
- Make the existing 80-character node-name limit Unicode-safe in both
  validation and `NodeEditingX` normalization.

## 0.8.0

- **Breaking:** replace the exported `NodeMutations` extension with
  `NodeEditingX`.
- **Breaking:** remove the public `withId()` and `withChildren()` node
  extension helpers. Structural identity and tree changes remain owned by
  scene-tree and rewrite operations.
- Keep `withName()`, `withXf()`, `withHidden()`, and `withLocked()` as the
  public immutable node-editing convenience API.

## 0.7.0

- **Breaking:** require explicit `version` and `data` values when constructing
  or deserializing `GroupBehaviorRef`.
- Remove implicit version `1` and empty-data defaults from behavior envelopes.

## 0.6.0

- **Breaking:** remove `SceneRenderBuilder` and
  `defaultSceneRenderBuilder`. Use a `ScenePreparer` for synchronous
  renderer-neutral scene transformation before calling
  `CanvasRenderPipeline.build()`, or call `build()` directly when no
  preparation is required.
- **Breaking:** expose one stable `CanvasRenderPipeline.services` bundle and
  remove `CanvasRenderPipeline.createServices()`. Preparation and final
  layout can now use the exact same `CoreServices` instance.
- Keep scene computation, paint-operation construction, content-bounds
  calculation, and `RenderSnapshot` creation exclusively in
  `CanvasRenderPipeline.build()`.
- **Breaking:** remove the unused `CanvasViewportPolicy` and
  `CanvasViewportSource` APIs. Use `CanvasViewportPlanner` and select the
  bounds to fit explicitly.
- **Breaking:** make `CanvasViewportPlanner.plan()` return
  `CanvasViewportTransform` directly and remove `CanvasViewportPlanResult`.
- **Breaking:** remove `computeViewportWithPadding`. Use
  `CanvasViewportPlanner.plan()` with `paddingPx`, or call
  `computeViewport` directly for low-level viewport math.

## 0.5.0

- **Breaking:** remove `TextMeasureCache` and the `textMeasureCache`
  parameters from `CoreServices`, `SceneRenderBuilder`,
  `defaultSceneRenderBuilder`, `CanvasRenderPipeline.createServices()`, and
  `CanvasRenderPipeline.build()`.
- **Breaking:** remove the deprecated
  `CanvasRenderPipeline.buildCanonical()` compatibility helper.
- Delegate text measurement directly to the host-provided `TextMeasurer`.
  Platform implementations are now responsible for their own caching strategy.

## 0.4.0

- **Breaking:** change `TextData.letterSpacing` and
  `TextMeasurer.measure` from `int` to `double`.
- Replace synthetic hair-space expansion with native logical-unit letter
  spacing while preserving the original text.
- Add `letterSpacing` to `DrawTextOp`.
- Remove `spacedText`, `measureSpaced`, and `measureSpacedText`.
- Existing non-zero spacing values now use the new native semantics.

## 0.3.0

- **Breaking:** remove the unused `label` named parameter from
  `History.reduce`.
- **Breaking:** remove the unused `label` named parameter from
  `History.withPresent`.
- History behavior and stored state are unchanged; labels were previously
  accepted but ignored.

## 0.2.2

- Add `CanvasFields.iconRef` as the shared field identity for an icon's
  reference value.

## 0.2.1

- Add `CanvasFieldKey`, `CanvasFields`, and `CanvasFieldKeyConverter` as a
  shared runtime field identity API.

## 0.2.0

- **Breaking:** replace the scene background color model with `CanvasFill` via
  `backgroundFill`.
- Support no-fill, solid, and gradient canvas backgrounds.
- Add package licensing details for the public release.

## 0.1.1

- Fix internal layout imports to avoid resolving duplicate canvas_core types.
- Move image/icon layout payload types into a shared internal layout payload
  file.

## 0.1.0

- Initial open-source release of canvas_core.
