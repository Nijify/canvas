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

Node _text(String id, {bool locked = false}) => Node.text(
  id: id,
  locked: locked,
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

  test('locked leaf is excluded unless includeLocked is true', () {
    final scene = _scene([_text('locked', locked: true)]);
    final computed = computeScene(scene, _services());
    final geometry = EditorGeometryIndex.fromComputed(computed);

    expect(
      pickTopAtScene(
        scene,
        Vec2.zero,
        computed: computed,
        geometry: geometry,
        selectLeaf: true,
      ),
      isNull,
    );

    expect(
      pickTopAtScene(
        scene,
        Vec2.zero,
        computed: computed,
        geometry: geometry,
        selectLeaf: true,
        includeLocked: true,
      )?.id,
      'locked',
    );
  });
}
