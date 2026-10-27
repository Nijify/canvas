import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';
final class _NoMetrics implements TextMeasurer {
  const _NoMetrics();
  @override
  Size2D measure({required String text, required String fontFamily,
    required int fontWeight, required double fontSize, required double letterSpacing}) => throw StateError('No metrics');
}
void main() {
  test('hidden transforms are available without resolving hidden resources', () {
    final parent = Affine2D(2, .5, .3, -1, 40, 20);
    final child = Affine2D.translation(10, 30);
    final scene = CanvasSceneDocument(children: [Node.group(id: 'hidden', hidden: true,
      xf: parent, children: [Node.text(id: 'text', xf: child,
        data: const TextData(text: 'Text', fontFamily: 'Missing', fontWeight: 400, fontSize: 12))])]);
    final computed = computeScene(scene, const CoreServices(textMeasurer: _NoMetrics()));
    expect(computed.worldById['text'], parent * child);
    expect(worldTransformOf(scene, 'text'), parent * child);
    expect(computed.drawList, isEmpty);
    expect(computed.layoutBoundsLocalById, isEmpty);
    expect(() => computed.worldById.clear(), throwsUnsupportedError);
  });
  test('sheared corners and bounds keep full affine geometry', () {
    final matrix = Affine2D(1, 0, 2, -1, 10, 20);
    final box = const Rect2D(0, 0, 10, 5);
    expect(transformedRectCorners(box, matrix), [
      const Vec2(10, 20), const Vec2(20, 20), const Vec2(30, 15), const Vec2(20, 15)]);
    expect(aabbOfTransformedRect(box, matrix), const Rect2D(10, 15, 30, 20));
  });
}
