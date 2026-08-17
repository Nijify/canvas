# canvas_editor_flutter example

A runnable standalone integration example for `canvas_editor_flutter`.

It demonstrates:

- the standard editor inspector and layers panel;
- user-image acquisition through `image_import.dart`;
- curated assets through `asset_library.dart`;
- host-owned background removal through `image_tools.dart`;
- JSON export;
- PNG sharing.

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
