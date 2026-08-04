# Unreleased

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
- Keep PNG export fitting behavior unchanged.

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
