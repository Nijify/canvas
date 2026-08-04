import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

final class _FakeTextMeasurer implements TextMeasurer {
  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) {
    return Size2D(text.length * fontSize * 0.6, fontSize);
  }
}

void main() {
  test('retains one service bundle for the pipeline lifetime', () {
    final pipeline = CanvasRenderPipeline(textMeasurer: _FakeTextMeasurer());

    final services = pipeline.services;

    expect(identical(pipeline.services, services), isTrue);
  });

  test('build snapshots the exact supplied prepared scene', () {
    final pipeline = CanvasRenderPipeline(textMeasurer: _FakeTextMeasurer());

    const preparedScene = CanvasSceneDocument(
      artboardSize: Size2D(300, 200),
      backgroundFill: CanvasFill.none(),
      backgroundOpacity: 0.75,
      children: <Node>[],
    );

    final snapshot = pipeline.build(preparedScene);

    expect(identical(snapshot.scene, preparedScene), isTrue);
    expect(snapshot.scene.backgroundOpacity, 0.75);
  });
}
