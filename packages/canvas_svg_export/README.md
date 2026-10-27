# canvas_svg_export

A strict, one-way SVG projection of an already-prepared `canvas_core` scene.

```dart
final evaluation = evaluateScene(preparedScene, services);
final result = exportPreparedSvg(evaluation: evaluation);
if (result.svg != null) {
  // Use the complete SVG document.
} else {
  // Inspect result.issues; no partial SVG is returned.
}
```

The supported profile exports none, solid, and explicit linear-gradient artboard
backgrounds, plus compiled paths with the same fill variants and undashed
strokes. It preserves visible path order and computed world transforms. Groups
are flattened for visual output. Node IDs, names, roles, and group behaviors
are not exported.

Gradients use their stored local endpoints and stops, emitted as SVG
`linearGradient` definitions with `userSpaceOnUse` coordinates and `pad`
spreading. Text, images, icons, and actively dashed strokes fail with structured
issues. Flutter currently paints strokes solid, so exporting an SVG dash would
change the visual result. Hidden nodes do not affect export.
Invalid scenes or missing computed geometry fail rather than producing
incomplete output.

The caller passes one evaluated snapshot that pairs its scene and geometry. Host
resolution and scene preparation remain outside this package. This package
does not consume Flutter painting state; its narrow supported profile does not
imply general SVG fidelity or pixel-identical rasterization across engines.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).
