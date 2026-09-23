// Path: packages/canvas_editor_flutter/test/interaction/snapping/layout_invariance_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/interaction/snapping/snap_index_scene.dart'
    show sceneObjectKeylines;
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
  }) => const Size2D(100, 20);
}

CoreServices _services() => CoreServices(textMeasurer: _TextMeasurer());

Node _text({
  String id = 'text',
  double shadow = 0,
  Transform2D xf = const Transform2D(),
  bool locked = false,
}) => Node.text(
  id: id,
  locked: locked,
  xf: xf,
  data: TextData(
    text: 'TEXT',
    fontFamily: 'Test',
    fontWeight: 400,
    fontSize: 20,
    appearance: CanvasAppearance(
      underlays: shadow == 0
          ? const []
          : [
              ShadowEffect(
                id: 'shadow',
                offset: Vec2(shadow, shadow),
                color: 0xFF111111,
              ),
            ],
    ),
  ),
);

CanvasSceneDocument _scene(List<Node> children) => CanvasSceneDocument(
  backgroundFill: const CanvasFill.none(),
  backgroundOpacity: 1,
  children: children,
);

void main() {
  for (final origin in OriginKind.values) {
    test(
      'source-underlay expansion preserves nested snap geometry: $origin',
      () {
        CanvasSceneDocument makeScene(double shadow) => _scene([
          Node.group(
            id: 'outer',
            xf: const Transform2D(
              position: Vec2(80, 40),
              rotationRad: 0.4,
              scale: Vec2(1.4, 0.8),
            ),
            children: [
              Node.group(
                id: 'inner',
                xf: const Transform2D(
                  position: Vec2(15, -20),
                  rotationRad: -0.7,
                  scale: Vec2(0.8, 1.6),
                ),
                children: [
                  _text(
                    shadow: shadow,
                    xf: Transform2D(
                      origin: origin,
                      customPivotPx: const Vec2(7, -3),
                      rotationRad: 0.3,
                      scale: const Vec2(-2, 0.5),
                    ),
                  ),
                  _text(
                    id: 'sibling',
                    xf: const Transform2D(position: Vec2(150, 30)),
                  ),
                ],
              ),
            ],
          ),
        ]);

        final beforeScene = makeScene(0);
        final afterScene = makeScene(200);

        final before = computeScene(beforeScene, _services());
        final after = computeScene(afterScene, _services());

        final beforeGeometry = EditorGeometryIndex.fromComputed(before);

        final afterGeometry = EditorGeometryIndex.fromComputed(after);

        final beforeSnaps = sceneObjectKeylines(
          beforeScene,
          before,
          geometry: beforeGeometry,
        );

        final afterSnaps = sceneObjectKeylines(
          afterScene,
          after,
          geometry: afterGeometry,
        );

        expect(
          afterSnaps.map((c) => (c.kind, c.axis, c.pos)),
          orderedEquals(beforeSnaps.map((c) => (c.kind, c.axis, c.pos))),
        );
      },
    );
  }

  test('excludes hidden, locked, empty, and ignored unresolved content', () {
    final scene = _scene([
      Node.group(
        id: 'hidden',
        hidden: true,
        children: [_text(id: 'hidden-text')],
      ),
      const Node.group(id: 'empty'),
      const Node.icon(
        id: 'unresolved',
        data: CanvasIconData(iconRef: 'missing'),
      ),
      _text(id: 'locked', locked: true),
    ]);

    final computed = computeScene(scene, _services());
    final geometry = EditorGeometryIndex.fromComputed(computed);

    expect(
      sceneObjectKeylines(
        scene,
        computed,
        geometry: geometry,
        ignoreIds: const {'unresolved'},
      ),
      isEmpty,
    );
  });
}
