import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_scene_upgrade/canvas_scene_upgrade.dart';
import 'package:test/test.dart';

final class _Metrics implements TextMeasurer {
  const _Metrics();
  @override
  Size2D measure({required String text, required String fontFamily,
    required int fontWeight, required double fontSize, required double letterSpacing}) => const Size2D(20, 10);
}
Map<String, Object?> _scene(Map<String, Object?> node) => {
  'sceneFormatVersion': 4, 'artboardSize': {'w': 200, 'h': 100},
  'backgroundFill': {'type': 'none'}, 'backgroundOpacity': 1, 'children': [node],
};
void main() {
  test('bakes geometry-center pivots without changing path coordinates', () {
    final source = {'kind': 'rect', 'x': 20, 'y': 30, 'width': 10, 'height': 20};
    final input = _scene({'runtimeType': 'path', 'id': 'p',
      'xf': {'scale': {'x': 2, 'y': 2}},
      'data': {'source': source, 'appearance': {'foreground': {'type': 'none'}}}});
    final output = decodeCanvasScene(upgradeCanvasScene(input));
    expect(output.children.single.xf, Affine2D(2, 0, 0, 2, -25, -40));
    expect(output.children.single.xf.transformPoint(const Vec2(25, 40)), const Vec2(25, 40));
    expect((output.children.single as PathNode).data.source.toJson(), source);
    expect(((input['children'] as List).single as Map)['xf'], {'scale': {'x': 2, 'y': 2}});
  });
  test('group center pivots require explicit text metrics', () {
    final input = _scene({'runtimeType': 'group', 'id': 'g',
      'xf': {'scale': {'x': 2, 'y': 2}}, 'children': [
        {'runtimeType': 'text', 'id': 't', 'xf': {'position': {'x': 50, 'y': 0}},
          'data': {'text': 'Text', 'fontFamily': 'Test', 'fontWeight': 400, 'fontSize': 10}},
      ]});
    expect(() => upgradeCanvasScene(input), throwsFormatException);
    final output = decodeCanvasScene(upgradeCanvasScene(input,
      services: const CoreServices(textMeasurer: _Metrics())));
    expect(output.children.single.xf, Affine2D(2, 0, 0, 2, -50, 0));
  });
}
