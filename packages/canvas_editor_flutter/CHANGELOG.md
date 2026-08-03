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
