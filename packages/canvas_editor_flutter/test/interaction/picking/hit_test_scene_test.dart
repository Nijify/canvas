// Path: packages/canvas_editor_flutter/test/interaction/picking/hit_test_scene_test.dart

import 'dart:math' as math;

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
      Node.path(
        id: 'path',
        data: PathData(
          source: GeneralPathSource.fromSvg(
            'M-12 -12L12 -12L12 12L-12 12Z M-5 -5L5 -5L5 5L-5 5Z',
          ),
          fillRule: FillRule.evenOdd,
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
      Node.path(
        id: 'path',
        data: PathData(
          source: const LineSource(x1: -10, x2: 10),
          appearance: CanvasAppearance(
            foreground: const CanvasFill.none(),
            stroke: CanvasStroke(color: 0xFF112233, width: 8),
          ),
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
    expect(computed.layoutBoundsLocalById['path'], const Rect2D(-10, 0, 10, 0));
    expect(
      pickLeafTopAtScene(
        scene,
        const Vec2(0, 5),
        computed: computed,
        geometry: geometry,
        minPathHitSlopScreenPx: 0,
      ),
      isNull,
    );
  });

  for (final vertical in [false, true]) {
    test(
      'unpainted ${vertical ? 'vertical' : 'horizontal'} line uses zoom slop',
      () {
        final scene = _scene([
          Node.path(
            id: 'path',
            data: PathData(
              source: PolylineSource(
                vertical
                    ? const [Vec2(0, -10), Vec2(0, 10)]
                    : const [Vec2(-10, 0), Vec2(10, 0)],
              ),
            ),
          ),
        ]);
        final computed = computeScene(scene, _services());
        final geometry = EditorGeometryIndex.fromComputed(computed);
        expect(computed.paintBoundsWorldById, isEmpty);
        for (final zoom in [0.5, 1.0, 4.0]) {
          Node? pick(double screenDistance) => pickLeafTopAtScene(
            scene,
            vertical
                ? Vec2(screenDistance / zoom, 0)
                : Vec2(0, screenDistance / zoom),
            computed: computed,
            geometry: geometry,
            viewportZoom: zoom,
          );
          expect(pick(5.5)?.id, 'path');
          expect(pick(6.5), isNull);
        }
      },
    );
  }

  test('nested transforms preserve the minimum screen-space hit floor', () {
    final scene = _scene([
      Node.group(
        id: 'group',
        xf: Affine2D.scale(4, 0.25),
        children: [
          Node.path(
            id: 'path',
            xf: Affine2D.rotation(math.pi / 4),
            data: PathData(source: const LineSource(x1: -10, x2: 10)),
          ),
        ],
      ),
    ]);
    final computed = computeScene(scene, _services());
    final geometry = EditorGeometryIndex.fromComputed(computed);
    final world = computed.worldById['path']!;
    final origin = world.transformPoint(Vec2.zero);
    final tangent = world.transformPoint(const Vec2(1, 0)) - origin;
    final normal = Vec2(-tangent.y, tangent.x).normalized;
    for (final zoom in [0.5, 1.0, 4.0]) {
      final point = origin + normal * (5.5 / zoom);
      final hit = pickLeafTopAtScene(
        scene,
        Vec2(point.x, point.y),
        computed: computed,
        geometry: geometry,
        viewportZoom: zoom,
      );
      expect(hit?.id, 'path');
    }
  });

  test('an unfilled ordinary path remains selectable inside its geometry', () {
    final scene = _scene([
      const Node.path(
        id: 'path',
        data: PathData(
          source: RectSource(x: -10, y: -10, width: 20, height: 20),
        ),
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
