# canvas_svg_export

A strict, one-way SVG projection of an already-prepared `canvas_core` scene.
This is an architecture proof, not a general SVG importer or a final product
export operation. It does not persist SVG or authoring metadata.

```dart
final computed = computeScene(preparedScene, services);
final result = exportPreparedSvg(scene: preparedScene, computed: computed);
if (result.svg != null) {
  // Use the complete SVG document.
} else {
  // Inspect result.issues; no partial SVG is returned.
}
```

The first profile exports a none/solid artboard background and compiled paths
with none/solid fills and undashed strokes. It preserves visible path order and
computed world transforms. Groups are flattened for visual output. Node IDs,
names, roles, and group behaviors are not exported.

Gradient fills, text, images, icons, and actively dashed strokes fail with
structured issues. The current gradient's angle/width rules are deliberately
not converted into SVG gradient semantics. Flutter currently ignores the path
model's dash list, so exporting an SVG dash would also change the visual result.
Hidden nodes do not affect export. Invalid scenes or missing computed geometry
fail rather than producing incomplete output.

The caller must pass geometry computed from the same prepared scene. Host
resolution and scene preparation remain outside this package. This package
does not consume `PaintOp`; its narrow supported profile does not imply general
SVG fidelity or pixel-identical rasterization across engines.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).
