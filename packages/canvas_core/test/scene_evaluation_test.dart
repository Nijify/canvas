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
  }) => Size2D(text.length * fontSize * 0.6, fontSize);
}

void main() {
  test('evaluates the exact prepared scene and computes draw order', () {
    final services = CoreServices(textMeasurer: _FakeTextMeasurer());
    const preparedScene = CanvasSceneDocument(
      artboardSize: Size2D(300, 200),
      backgroundFill: CanvasFill.none(),
      backgroundOpacity: 0.75,
      children: <Node>[
        Node.text(
          id: 'label',
          data: TextData(
            text: 'Hi',
            fontFamily: 'Ahem',
            fontWeight: 400,
            fontSize: 20,
          ),
        ),
      ],
    );

    final evaluation = evaluateScene(preparedScene, services);

    expect(identical(evaluation.scene, preparedScene), isTrue);
    expect(evaluation.computed.drawList.map((item) => item.leafId), ['label']);
    expect(evaluation.contentBounds, isNull);
  });
}
