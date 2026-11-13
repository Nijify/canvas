import 'dart:convert';

import 'package:canvas_core/canvas_core.dart';

// Fixed-width metrics make this example runnable without loading any fonts.
// Rendering hosts should supply measurement for their actual fonts.
final class _ExampleTextMeasurer implements TextMeasurer {
  const _ExampleTextMeasurer();

  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) {
    if (text.isEmpty) return Size2D.zero;
    return Size2D(
      text.length * fontSize * 0.6 + (text.length - 1) * letterSpacing,
      fontSize,
    );
  }
}

void main() {
  final scene = CanvasSceneDocument(
    artboardSize: const Size2D(320, 200),
    backgroundFill: const CanvasFill.solid(0xfff5f5f5),
    backgroundOpacity: 1,
    children: [
      Node.path(
        id: 'panel',
        geometry: const RectSource(x: -140, y: -60, width: 280, height: 120),
        xf: Affine2D.translation(160, 100),
        appearance: const CanvasAppearance(
          foreground: CanvasFill.solid(0xffddeeff),
        ),
      ),
      Node.text(
        id: 'greeting',
        text: 'Hello, Canvas!',
        fontFamily: 'ExampleMono',
        fontWeight: 400,
        fontSize: 24,
        xf: Affine2D.translation(160, 100),
      ),
    ],
  );

  // Persist only the design. Evaluation produces transient geometry separately.
  final json = encodeCanvasScene(scene);
  final restored = decodeCanvasScene(json);
  final evaluation = evaluateScene(
    restored,
    const CoreServices(textMeasurer: _ExampleTextMeasurer()),
  );

  print(const JsonEncoder.withIndent('  ').convert(json));
  print(
    'Paint order: ${evaluation.computed.drawList.map((item) => item.leafId).join(', ')}',
  );
  print('Panel bounds: ${evaluation.computed.layoutBoundsLocalById['panel']}');
}
