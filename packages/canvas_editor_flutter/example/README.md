# canvas_editor_flutter example

A runnable standalone integration example for `canvas_editor_flutter`.

The hosted web demo is available at:

<https://nijify.github.io/canvas/>

It demonstrates:

- the standard editor inspector and layers panel;
- bundled vector icons with editable fills and shadows;
- user-image acquisition through `image_import.dart`;
- curated assets through `asset_library.dart`;
- host-owned background removal through `image_tools.dart`;
- JSON export;
- PNG sharing.

## Vector icons

Select the ring on the canvas or the **Vector icon** row in Layers. In the
inspector, choose **Diamond**, **Ring**, or **Wide arrow**, then change its size,
fill, gradient, or shadows. PNG sharing uses the same prepared icon catalog as
the editor.

The three original fixtures in `assets/icons/` use the package's
[Apache 2.0 license](../LICENSE). Each JSON file contains only `source`, `viewBox`
(`[x, y, width, height]`), and `fillRule`. The diamond uses straight segments;
the ring uses cubic curves and an even-odd hole; the arrow has a non-square
viewBox with a nonzero origin and authored margins.

`example_icon_catalog.dart` owns the short ref/label/asset list and loads the
files through `AssetBundle`. It constructs public `CommandPathSource` and
`ResolvedIcon` values before creating the editor session, then exposes
synchronous lookup. Scene JSON stores icon references; reopening it requires
the same catalog. Text continues to use the bundled typography font.

To add a prepared example icon, put its JSON file in `assets/icons/` and add one
entry to the list. These files already contain normalized command geometry;
loading them does not import raw SVG or Font Awesome source files. Resource
loading policy belongs to the host application.

## Background-removal demo

Choose:

`Add → Assets → Background removal demo`

Select the inserted image and use:

`Image tools → Remove background`

The example does not run background-removal ML.

Its `BackgroundRemovalPort` is deliberately deterministic: the bundled demo
input maps to a precomputed transparent PNG with the same raster dimensions.

Other images return `unsupported`.

This demonstrates the host integration boundary only:

```text
sourceRef
  → BackgroundRemovalPort
  → durable replacement sourceRef
```

Real applications may implement that port using local processing, a backend
service, durable media storage, or another provider.

## Run

From the repository root:

```sh
flutter pub get
cd packages/canvas_editor_flutter/example
flutter run -d chrome
```

## Build for GitHub Pages

From the example directory:

```sh
flutter build web --release --base-href /canvas/
```

The Pages workflow publishes `build/web` after changes are merged to `master`.
