## 0.4.0

- **Breaking:** require canvas_core 0.17.x and reuse its shared M/L/C/Z path writer.
- Remove duplicate command writing and validation. Keep the strict export profile,
  unsupported-feature reporting, and rejection of icon nodes unchanged.

## 0.3.0

- **Breaking:** require `canvas_core 0.16.x` and export path paint from
  `CanvasAppearance` and `CanvasStroke`.
- Preserve active stroke settings and alpha. Reject active dash metadata to
  match Flutter's solid rendering; inactive configurations add no dash issue.
- **Breaking:** use shared scene integrity and remove `SvgExportIssue.path`;
  invalid input still returns an `invalidScene` failure.

## 0.2.0

- **Breaking:** require `canvas_core 0.15.x` and consume geometry-only
  `PathIR`, reading authored path appearance from `PathData`.

## 0.1.0

- Introduce strict SVG export for prepared ordinary-path scenes, returning
  structured issues instead of partial output for unsupported content.
