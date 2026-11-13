import 'package:canvas_core/canvas_core.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: _RendererExample()));
}

class _RendererExample extends StatefulWidget {
  const _RendererExample();

  @override
  State<_RendererExample> createState() => _RendererExampleState();
}

class _RendererExampleState extends State<_RendererExample> {
  // Measurement and painting share one pipeline owned by this surface.
  final _text = FlutterTextPipeline();
  late final SceneEvaluation _evaluation;

  @override
  void initState() {
    super.initState();
    final scene = CanvasSceneDocument(
      artboardSize: const Size2D(320, 200),
      backgroundFill: const CanvasFill.solid(0xffeef2ff),
      backgroundOpacity: 1,
      children: [
        Node.path(
          id: 'panel',
          geometry: const RectSource(
            x: -136,
            y: -64,
            width: 272,
            height: 128,
            rx: 16,
            ry: 16,
          ),
          xf: Affine2D.translation(160, 100),
          appearance: const CanvasAppearance(
            foreground: CanvasFill.solid(0xff4338ca),
          ),
        ),
        Node.text(
          id: 'greeting',
          text: 'Hello, Canvas!',
          fontFamily: 'sans-serif',
          fontWeight: 600,
          fontSize: 28,
          xf: Affine2D.translation(160, 100),
          appearance: const CanvasAppearance(
            foreground: CanvasFill.solid(0xffffffff),
          ),
        ),
      ],
    );
    _evaluation = evaluateScene(scene, CoreServices(textMeasurer: _text));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Canvas renderer')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FittedBox(
            child: CustomPaint(
              size: const Size(320, 200),
              painter: _ScenePainter(_evaluation, _text),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.evaluation, this.text);

  final SceneEvaluation evaluation;
  final FlutterTextPipeline text;

  @override
  void paint(Canvas canvas, Size size) {
    CanvasRenderer(text: text).paintScene(canvas, evaluation);
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) {
    return oldDelegate.evaluation != evaluation || oldDelegate.text != text;
  }
}
