## 0.3.0

- Use shared fail-fast scene integrity before capability checks, retaining the
  `invalidScene` failure result. Remove the unused `SvgExportIssue.path` field;
  scene errors no longer expose a structured validation path.

- **Breaking:** require `canvas_core 0.16.x` and export authored path paint from
  `CanvasAppearance.foreground` and the optional `CanvasStroke` configuration.
- Preserve fill rule and active stroke width, caps, joins, miter limit, and
  alpha. Reject active dash metadata because Flutter currently paints it solid;
  inactive stroke configurations do not introduce unsupported-dash issues.

## 0.2.0

- **Breaking:** require `canvas_core 0.15.x` and consume geometry-only
  `PathIR`, reading authored path appearance from `PathData`.

## 0.1.0

- Introduce strict SVG export for prepared ordinary-path scenes, returning
  structured issues instead of partial output for unsupported content.
