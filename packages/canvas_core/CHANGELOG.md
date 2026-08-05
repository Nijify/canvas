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
