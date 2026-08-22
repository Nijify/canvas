# 0.11.2

- Invalidate cached text measurement and rendered layout when Flutter reports
  that the available fonts have changed.
- Size newly imported images from stable intrinsic metadata while retaining the
  existing 200-by-200 fallback when metadata is unavailable.
- Update the runnable example with deterministic symbol fallback, data-URI
  image metadata, and clearer embedded-image JSON export feedback.

# 0.11.1

- Add the optional `image_tools.dart` capability entrypoint.
- Add the provider-neutral `BackgroundRemovalPort` and typed background-removal
  results.
- Add `backgroundRemovalExtension` for host-owned background removal inside the
  standard Image inspector.
- Keep background removal target-safe across asynchronous selection, source,
  target, field-editability, and prepared-scene changes.
- Commit successful replacements through the registered
  `CanvasFields.imageSource` field path so normal field policy and undo/redo
  remain authoritative.
- Keep image processing, persistence, provider lifecycle, byte handling, and
  cleanup of unreferenced outputs outside Canvas.

# 0.11.0

- **Breaking:** image import no longer participates in the exclusive
  `InspectorBuilder` chain. It contributes source controls to the standard
  inspector instead, so an exclusive inspector override now suppresses image
  import content together with the intrinsic inspector.
- Add `InspectorSectionBuilder` and
  `EditorSurfaceFeatures.inspectorSections` for additive standard-inspector
  content composed in extension registration order.
- Keep additive inspector content inside the standard inspector card and before
  intrinsic field controls.
- Make asynchronous image replacement target-safe by rejecting stale results
  after selection, source, target, or field-editability changes.

# 0.10.0

- **Breaking:** remove `InspectorFieldRow.forceDisabled` and
  `InspectorFieldRow.disabledReasonOverride`; registered field editability now
  flows through `FieldState.disabledReason`.
- Add `EditorDocumentAdapter.fieldEditDisabledReason(...)` for
  source-document-aware registered literal edit restrictions.
- Enforce source-document field denial in `EditorRuntime.commitField()` using
  the current canonical transaction state.
- Apply source-document editability to scene-level registered fields.
- Export `kSceneFieldsId` through the public `extensions.dart` entrypoint.

# 0.9.0

- **Breaking:** require `canvas_core 0.8.x` and
  `canvas_renderer_flutter 0.7.x`.
- **Breaking:** remove `PngExportAvailability`; configure `canShare` and
  `canSave` directly on `PngExportCapability`.
- **Breaking:** remove `JsonExportAvailability`; configure `canCopy` and
  `canSave` directly on `JsonExportCapability`.
- **Breaking:** remove the editor-owned `JsonMap` alias. Use
  `Map<String, Object?>` or a domain-owned alias where needed.
- Adopt the narrowed `NodeEditingX` runtime editing surface.
- No intended editor, rendering, preparation, or export behavior changes.

# 0.8.0

- **Breaking:** replace the split `EditorExports` and `PngOutputPort` PNG
  contracts with one host-owned `PngExportPort`.
- Pass both the canonical editable scene and the prepared render scene to PNG
  export hosts.
- Move final PNG resource preparation, rendering, policy, and output ownership
  behind the host export port.
- Keep scene JSON export based on the canonical editable scene.
- Update the runnable example to demonstrate host-owned PNG rendering and
  sharing through `PngExportPort`.

# 0.7.0

- **Breaking:** require `canvas_core 0.7.x`.
- **Breaking:** require `canvas_renderer_flutter 0.6.x`.
- Support the explicit component behavior `version` and `data` envelope introduced by `canvas_core 0.7.0`.

# 0.6.0

- **Breaking:** remove the redundant `EditorActionIds.duplicateGroup` and
  `EditorActionIds.deleteGroup` actions.
- **Breaking:** require `EditorActionDispatcher` to receive a non-null
  `EditorActionContext`.
- Keep the generic Duplicate and Delete actions working for groups and leaf
  nodes.

# 0.5.0

- **Breaking:** require `canvas_core 0.6.x` and
  `canvas_renderer_flutter 0.5.x`.
- **Breaking:** replace `EditorExtension.renderBuilder` and
  `StaticEditorExtension.renderBuilder` with `scenePreparer`.
- **Breaking:** reject extension compositions with more than one non-null
  `ScenePreparer` by throwing `StateError`.
- **Breaking:** change `EditorExports.renderPng()` to accept a typed
  `preparedScene` instead of scene JSON.
- Resolve source documents through `EditorDocumentAdapter`, apply optional
  scene preparation once, and then call `CanvasRenderPipeline.build()`.
- Preserve canonical editable scenes for editing, history, persistence, and
  scene JSON export while using prepared runtime scenes for drawing and PNG
  export.
- Remove the PNG scene JSON encode/decode round trip.
- Consume the `CanvasViewportTransform` returned directly by
  `CanvasViewportPlanner.plan()`.

# 0.4.0

- **Breaking:** require `canvas_core 0.5.x` and
  `canvas_renderer_flutter 0.4.x`.
- Use one `FlutterTextPipeline` for both core text measurement and Flutter text
  painting.
- Remove the editor's separate `FlutterTextMeasurer` and session-long core text
  measurement cache.
- Clear cached text layouts after new fonts load and before scheduling layout
  invalidation.
- Dispose the editor-owned text pipeline when the editor session is destroyed.

# 0.3.1

- Use `FlutterImagePool` as the editor's single image and intrinsic-state owner.
- Remove duplicate image-intrinsics lifecycle management.
- Require `canvas_renderer_flutter 0.3.x`.

# 0.3.0

- **Breaking:** remove `EditorExportFit` and use the shared `CanvasFit` type from
  `canvas_core`.
- Keep the default export fit as `CanvasFit.contain`.

# 0.2.0

- **Breaking:** require `canvas_core 0.4.x` and
  `canvas_renderer_flutter 0.2.x`.
- Preserve fractional letter spacing through editing and history.
- Use quarter-pixel letter-spacing controls in the inspector.

# 0.1.1

- Made image replacement actions responsive in narrow inspector layouts.
- Added compact Gallery and Camera actions with enlarged-text coverage.

# 0.1.0

- Initial public release.
- Added the turnkey `CanvasSceneEditor` embedding API.
- Added selection, movement, inspection, layers, undo and redo.
- Added extension points for custom documents, rendering, fields, actions, and editor chrome.
- Added optional image import, PNG export, and JSON export capabilities.
- Added English-language editor UI.
