import 'dart:math' as math;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/interaction/geometry/editor_geometry_index.dart';
import 'package:canvas_editor_flutter/src/interaction/picking/hit_test_scene.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class _NoText implements TextMeasurer {
  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) => throw StateError('Icon picking must not measure text.');
}

class _Icons implements IconResolver {
  @override
  ResolvedIcon? resolve(String ref) => ResolvedIcon(
    pathIR: PathIR([
      PathCmd.moveTo(const Vec2(0, 0)),
      PathCmd.lineTo(const Vec2(32, 0)),
      PathCmd.lineTo(const Vec2(32, 16)),
      PathCmd.lineTo(const Vec2(0, 16)),
      PathCmd.close(),
      PathCmd.moveTo(const Vec2(12, 4)),
      PathCmd.lineTo(const Vec2(20, 4)),
      PathCmd.lineTo(const Vec2(20, 12)),
      PathCmd.lineTo(const Vec2(12, 12)),
      PathCmd.close(),
    ]),
    viewBox: const Rect2D(0, 0, 32, 16),
    fillRule: FillRule.evenOdd,
  );
}

CanvasSceneDocument _scene({Transform2D group = const Transform2D()}) =>
    CanvasSceneDocument(
      backgroundFill: const CanvasFill.none(),
      backgroundOpacity: 1,
      children: [
        const Node.path(
          id: 'under',
          data: PathData(source: RectSource(x: -200, y: -200, width: 400, height: 400)),
        ),
        Node.group(
          id: 'group',
          xf: group,
          children: const [
            Node.icon(
              id: 'icon',
              data: CanvasIconData(
                iconRef: 'ring',
                sizePx: 96,
                appearance: CanvasAppearance(
                  foreground: CanvasFill.none(),
                  underlays: [
                    ShadowEffect(
                      id: 's',
                      offset: Vec2(100, 0),
                      color: 0xff000000,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );

void main() {
  test('holes and viewBox margins select the topmost icon square', () {
    final scene = _scene();
    final computed = computeScene(
      scene,
      CoreServices(textMeasurer: _NoText(), icons: _Icons()),
    );
    final geometry = EditorGeometryIndex.fromComputed(computed);
    Node? pick(Vec2 point, {bool leaf = true}) => pickTopAtScene(
      scene,
      point,
      computed: computed,
      geometry: geometry,
      selectLeaf: leaf,
      minPathHitSlopScreenPx: 0,
    );
    expect(pick(Vec2.zero)?.id, 'icon'); // Filled-path hole.
    expect(pick(const Vec2(0, 40))?.id, 'icon'); // Above fitted artwork.
    expect(pick(const Vec2(48, 48))?.id, 'icon');
    expect(pick(const Vec2(49, 0))?.id, 'under');
    expect(pick(const Vec2(100, 0))?.id, 'under'); // Shadow is not a target.
    expect(pick(Vec2.zero, leaf: false)?.id, 'group');
  });

  test('square picking follows nested rotation and nonuniform reflection', () {
    final scene = _scene(
      group: Transform2D(
        position: const Vec2(70, -35),
        rotationRad: math.pi / 3,
        scale: const Vec2(-2, 0.5),
      ),
    );
    final computed = computeScene(
      scene,
      CoreServices(textMeasurer: _NoText(), icons: _Icons()),
    );
    final geometry = EditorGeometryIndex.fromComputed(computed);
    Vec2 world(Vec2 local) {
      final point = vm.Vector3(local.x, local.y, 0);
      computed.worldById['icon']!.transform3(point);
      return Vec2(point.x, point.y);
    }

    Node? pick(Vec2 local) => pickLeafTopAtScene(
      scene,
      world(local),
      computed: computed,
      geometry: geometry,
      minPathHitSlopScreenPx: 0,
    );
    expect(pick(Vec2.zero)?.id, 'icon');
    expect(pick(const Vec2(0, 40))?.id, 'icon');
    expect(pick(const Vec2(47, -47))?.id, 'icon');
    expect(pick(const Vec2(50, 0))?.id, isNot('icon'));
  });
}
