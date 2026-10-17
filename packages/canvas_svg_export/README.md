# canvas_svg_export

A strict, one-way SVG projection of an already-prepared `canvas_core` scene.

```dart
final computed = computeScene(preparedScene, services);
final result = exportPreparedSvg(scene: preparedScene, computed: computed);
if (result.svg != null) {
  // Use the complete SVG document.
} else {
  // Inspect result.issues; no partial SVG is returned.
}
```

The supported profile exports none, solid, and explicit linear-gradient artboard
backgrounds, plus compiled paths with the same fill variants and undashed
strokes. Path paint comes from `PathData.appearance`: `foreground` supplies the
fill and an optional `CanvasStroke` supplies stroke color, width, caps, joins,
and miter limit. `PathData.fillRule` supplies the fill rule. The exporter
preserves visible path order and computed world transforms. Groups
are flattened for visual output. Node IDs, names, roles, and group behaviors
are not exported.

Gradients use their stored local endpoints and stops, emitted as SVG
`linearGradient` definitions with `userSpaceOnUse` coordinates and `pad`
spreading. Text, images, icons, and actively dashed strokes fail with structured
issues. Stroke alpha must be nonzero and width positive for dash metadata to
trigger rejection; inactive stroke configurations add no dash issue. Flutter
currently paints configured strokes solid, so exporting an SVG dash would
change the visual result. Hidden nodes do not affect export.
Invalid scenes or missing computed geometry fail rather than producing
incomplete output.

The caller must pass geometry computed from the same prepared scene. Host
resolution and scene preparation remain outside this package. This package
does not consume Flutter painting state; its narrow supported profile does not
imply general SVG fidelity or pixel-identical rasterization across engines.

Use `canvas_svg_export 0.3.x` with `canvas_core 0.16.x`. See the
[scene-v3 upgrade guide](../canvas_core/doc/migration-v3.md) when adopting the
shared path appearance model.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).
