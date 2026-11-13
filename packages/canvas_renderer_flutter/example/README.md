# Renderer example

[`canvas_renderer_flutter_example.dart`](canvas_renderer_flutter_example.dart)
paints an ordinary path and text scene through a Flutter `CustomPainter`. One
`FlutterTextPipeline` supplies both measurement and painting and is disposed
when the preview surface is removed. The example uses system fonts and requires
no assets or network access.

Copy the entry point into a Flutter application's `lib/main.dart` after adding
`canvas_core` and `canvas_renderer_flutter` as dependencies, then run `flutter run`.

From this repository, reuse the existing Flutter web runner:

```bash
cd packages/canvas_editor_flutter/example
flutter run -d chrome --target ../../canvas_renderer_flutter/example/canvas_renderer_flutter_example.dart
```

The renderer example uses only core, renderer, and Flutter APIs. It does not
require the editor package in a standalone application.
