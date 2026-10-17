// Path: packages/canvas_editor_flutter/test/interaction/picking/hit_test_scene_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/interaction/picking/hit_test_scene.dart';
import 'package:canvas_editor_flutter/src/interaction/geometry/editor_geometry_index.dart';
import 'package:flutter_test/flutter_test.dart';

class _TextMeasurer implements TextMeasurer {
  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) => const Size2D(20, 20);
}

CoreServices _services() => CoreServices(textMeasurer: _TextMeasurer());

Node _text(String id, {bool hidden = false}) => Node.text(
  id: id,
  hidden: hidden,
  data: const TextData(
    text: 'X',
    fontFamily: 'Test',
    fontWeight: 400,
    fontSize: 20,
  ),
);

CanvasSceneDocument _scene(List<Node> children) => CanvasSceneDocument(
  backgroundFill: const CanvasFill.none(),
  backgroundOpacity: 1,
  children: children,
);

void main() {
  test('path picking uses the authored fill rule', () {
    final scene = _scene([
      const Node.path(
        id: 'path',
        data: PathData(
          points: [
            Vec2(-12, -12),
            Vec2(12, -12),
            Vec2(12, 12),
            Vec2(-12, 12),
            Vec2(-12, -12),
            null,
            Vec2(-5, -5),
            Vec2(5, -5),
            Vec2(5, 5),
            Vec2(-5, 5),
            Vec2(-5, -5),
          ],
          fillRule: FillRule.evenOdd,
          strokeWidth: 0,
        ),
      ),
    ]);
    final computed = computeScene(scene, _services());
    final geometry = EditorGeometryIndex.fromComputed(computed);

    Node? pick(Vec2 point) => pickLeafTopAtScene(
      scene,
      point,
      computed: computed,
      geometry: geometry,
      minPathHitSlopScreenPx: 0,
    );

    expect(pick(Vec2.zero), isNull);
    expect(pick(const Vec2(8, 0))?.id, 'path');
  });

  test('path picking uses the authored stroke width', () {
    final scene = _scene([
      const Node.path(
        id: 'path',
        data: PathData(
          points: [Vec2(-10, 0), Vec2(10, 0)],
          strokeColor: 0xFF112233,
          strokeWidth: 8,
        ),
      ),
    ]);
    final computed = computeScene(scene, _services());
    final geometry = EditorGeometryIndex.fromComputed(computed);

    final hit = pickLeafTopAtScene(
      scene,
      const Vec2(0, 3),
      computed: computed,
      geometry: geometry,
      minPathHitSlopScreenPx: 0,
    );

    expect(hit?.id, 'path');
  });

  test('an unfilled ordinary path remains selectable inside its geometry', () {
    final scene = _scene([
      const Node.path(
        id: 'path',
        data: PathData(source: RectSource(20, 20), strokeWidth: 0),
      ),
    ]);
    final computed = computeScene(scene, _services());

    final hit = pickLeafTopAtScene(
      scene,
      Vec2.zero,
      computed: computed,
      geometry: EditorGeometryIndex.fromComputed(computed),
      minPathHitSlopScreenPx: 0,
    );

    expect(hit?.id, 'path');
  });

  test('picks the topmost overlapping leaf', () {
    final scene = _scene([_text('bottom'), _text('top')]);
    final computed = computeScene(scene, _services());
    final geometry = EditorGeometryIndex.fromComputed(computed);

    final hit = pickTopAtScene(
      scene,
      Vec2.zero,
      computed: computed,
      geometry: geometry,
      selectLeaf: true,
    );

    expect(hit?.id, 'top');
  });

  test('default picking returns the nearest selectable group', () {
    final scene = _scene([
      Node.group(id: 'group', children: [_text('leaf')]),
    ]);
    final computed = computeScene(scene, _services());
    final geometry = EditorGeometryIndex.fromComputed(computed);

    final hit = pickTopAtScene(
      scene,
      Vec2.zero,
      computed: computed,
      geometry: geometry,
    );

    expect(hit?.id, 'group');
  });

  test('selectLeaf returns the leaf inside a group', () {
    final scene = _scene([
      Node.group(id: 'group', children: [_text('leaf')]),
    ]);
    final computed = computeScene(scene, _services());
    final geometry = EditorGeometryIndex.fromComputed(computed);

    final hit = pickTopAtScene(
      scene,
      Vec2.zero,
      computed: computed,
      geometry: geometry,
      selectLeaf: true,
    );

    expect(hit?.id, 'leaf');
  });

  test('ignoring a group ignores its whole subtree', () {
    final scene = _scene([
      Node.group(id: 'group', children: [_text('leaf')]),
    ]);
    final computed = computeScene(scene, _services());
    final geometry = EditorGeometryIndex.fromComputed(computed);

    final hit = pickTopAtScene(
      scene,
      Vec2.zero,
      computed: computed,
      geometry: geometry,
      ignoreIds: const {'group'},
    );

    expect(hit, isNull);
  });

  test('hidden leaves do not participate in picking', () {
    final scene = _scene([_text('visible'), _text('hidden', hidden: true)]);

    final computed = computeScene(scene, _services());
    final geometry = EditorGeometryIndex.fromComputed(computed);

    final hit = pickTopAtScene(
      scene,
      Vec2.zero,
      computed: computed,
      geometry: geometry,
      selectLeaf: true,
    );

    expect(hit?.id, 'visible');
  });
}
