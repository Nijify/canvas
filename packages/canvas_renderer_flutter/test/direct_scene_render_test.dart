import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ui.Color> _pixel(CanvasSceneDocument scene, int x, int y) async {
  final text = FlutterTextPipeline();
  try {
    final evaluation = evaluateScene(scene, CoreServices(textMeasurer: text));
    final recorder = ui.PictureRecorder();
    CanvasRenderer(text: text).paintScene(ui.Canvas(recorder), evaluation);
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(64, 64);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final rgba = data!.buffer.asUint8List();
        final i = (y * 64 + x) * 4;
        return ui.Color.fromARGB(
          rgba[i + 3],
          rgba[i],
          rgba[i + 1],
          rgba[i + 2],
        );
      } finally {
        image.dispose();
      }
    } finally {
      picture.dispose();
    }
  } finally {
    text.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'paints nested group transforms and sibling order from computed scene',
    () async {
      const scene = CanvasSceneDocument(
        artboardSize: Size2D(64, 64),
        backgroundFill: CanvasFill.none(),
        backgroundOpacity: 1,
        children: [
          Node.group(
            id: 'group',
            xf: Transform2D(
              position: Vec2(24, 24),
              origin: OriginKind.custom,
              customPivotPx: Vec2.zero,
            ),
            children: [
              Node.path(
                id: 'red',
                data: PathData(
                  source: RectSource(x: -16, y: -16, width: 32, height: 32),
                  appearance: CanvasAppearance(
                    foreground: CanvasFill.solid(0xFFFF0000),
                  ),
                ),
              ),
              Node.path(
                id: 'blue',
                data: PathData(
                  source: RectSource(x: -6, y: -6, width: 12, height: 12),
                  appearance: CanvasAppearance(
                    foreground: CanvasFill.solid(0xFF0000FF),
                  ),
                ),
              ),
            ],
          ),
        ],
      );

      expect(await _pixel(scene, 24, 24), const ui.Color(0xFF0000FF));
      expect(await _pixel(scene, 12, 24), const ui.Color(0xFFFF0000));
      expect(await _pixel(scene, 2, 2), const ui.Color(0x00000000));
    },
  );

  test('null image asset leaves an unfilled frame transparent', () async {
    const scene = CanvasSceneDocument(
      artboardSize: Size2D(64, 64),
      backgroundFill: CanvasFill.none(),
      backgroundOpacity: 1,
      children: [
        Node.image(
          id: 'empty',
          xf: Transform2D(position: Vec2(32, 32)),
          data: ImageData(size: Size2D(24, 24)),
        ),
      ],
    );

    expect(await _pixel(scene, 32, 32), const ui.Color(0x00000000));
  });
}
