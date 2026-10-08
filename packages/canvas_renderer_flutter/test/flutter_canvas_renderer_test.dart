import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturingTextPipeline extends FlutterTextPipeline {
  TextSpec? lastSpec;
  ui.Color? lastSolid;
  ui.Shader? lastShader;

  @override
  void paint(
    ui.Canvas canvas,
    ui.Offset origin,
    TextSpec s, {
    ui.Color? solid,
    ui.Shader? shader,
    TextOriginKind originKind = TextOriginKind.baseline,
  }) {
    lastSpec = s;
    lastSolid = solid;
    lastShader = shader;
  }
}

CanvasSceneDocument _textScene(String value, CanvasFill fill) =>
    CanvasSceneDocument(
      backgroundFill: const CanvasFill.none(),
      backgroundOpacity: 1,
      children: [
        Node.text(
          id: 'text',
          data: TextData(
            text: value,
            fontFamily: 'Inter',
            fontWeight: 400,
            fontSize: 20,
            letterSpacing: 1.25,
            appearance: CanvasAppearance(foreground: fill),
          ),
        ),
      ],
    );

void _paint(CanvasSceneDocument scene, _CapturingTextPipeline pipeline) {
  final evaluation = evaluateScene(scene, CoreServices(textMeasurer: pipeline));
  final recorder = ui.PictureRecorder();
  CanvasRenderer(text: pipeline).paintScene(ui.Canvas(recorder), evaluation);
  recorder.endRecording().dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'passes scene solid color and raw Unicode text to the text pipeline',
    () {
      final pipeline = _CapturingTextPipeline();
      const original = 'A🙂e\u0301👨‍👩‍👧‍👦';
      _paint(
        _textScene(original, const CanvasFill.solid(0xFFAA8844)),
        pipeline,
      );
      expect(pipeline.lastSpec?.text, original);
      expect(pipeline.lastSpec?.letterSpacing, 1.25);
      expect(pipeline.lastSolid, const ui.Color(0xFFAA8844));
      expect(pipeline.lastShader, isNull);
      pipeline.dispose();
    },
  );

  test('passes scene gradient as a shader to the text pipeline', () {
    final pipeline = _CapturingTextPipeline();
    _paint(
      _textScene(
        'Hi',
        const CanvasFill.gradient(
          LinearGradientSpec(
            color1: 0xFF0000FF,
            color2: 0xFF00FF00,
            angle: 0,
            width: 20,
          ),
        ),
      ),
      pipeline,
    );
    expect(pipeline.lastSpec?.text, 'Hi');
    expect(pipeline.lastShader, isNotNull);
    pipeline.dispose();
  });

  test(
    'renderer options default to interactive missing-image placeholders',
    () {
      const options = CanvasRendererOptions();
      expect(options.imageFilterQuality, ui.FilterQuality.none);
      expect(options.missingImageBehavior, MissingImageBehavior.placeholder);
    },
  );

  test('renderer options can skip missing images for output paths', () {
    const options = CanvasRendererOptions(
      missingImageBehavior: MissingImageBehavior.skip,
    );
    expect(options.missingImageBehavior, MissingImageBehavior.skip);
  });

  test('renderer options preserve explicit image filter quality', () {
    const options = CanvasRendererOptions(
      imageFilterQuality: ui.FilterQuality.medium,
      missingImageBehavior: MissingImageBehavior.skip,
    );
    expect(options.imageFilterQuality, ui.FilterQuality.medium);
    expect(options.missingImageBehavior, MissingImageBehavior.skip);
  });
}
