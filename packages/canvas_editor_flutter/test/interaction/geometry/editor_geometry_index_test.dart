// Path: packages/canvas_editor_flutter/test/interaction/geometry/editor_geometry_index_test.dart

import 'dart:math' as math;

import 'package:canvas_core/canvas_core_runtime.dart';
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
  }) {
    return const Size2D(100, 20);
  }
}

CoreServices _services() => CoreServices(textMeasurer: _TextMeasurer());

CanvasSceneDocument _scene(List<Node> children) => CanvasSceneDocument(
  backgroundFill: const CanvasFill.none(),
  backgroundOpacity: 1,
  children: children,
);

Node _text({String id = 'text', Affine2D xf = const Affine2D.identity()}) =>
    Node.text(
      id: id,
      xf: xf,
      data: const TextData(
        text: 'TEXT',
        fontFamily: 'Test',
        fontWeight: 400,
        fontSize: 20,
      ),
    );

void _expectRect(Rect2D? actual, Rect2D expected) {
  expect(actual, isNotNull);

  final rect = actual!;

  expect(rect.left, closeTo(expected.left, 1e-8));
  expect(rect.top, closeTo(expected.top, 1e-8));
  expect(rect.right, closeTo(expected.right, 1e-8));
  expect(rect.bottom, closeTo(expected.bottom, 1e-8));
}

void main() {
  test('derives leaf world layout bounds from core geometry', () {
    final scene = _scene([
      _text(
        xf: (Affine2D.translation(30, 40) * Affine2D.rotation(0.35) * Affine2D.scale(1.5, 0.75)),
      ),
    ]);

    final computed = computeScene(scene, _services());

    final geometry = EditorGeometryIndex.fromComputed(computed);

    final local = computed.layoutBoundsLocalById['text']!;
    final world = computed.worldById['text']!;

    final expected = aabbOfTransformedRect(local, world);

    _expectRect(geometry.layoutBoundsWorldById['text'], expected);
  });

  test('derives inverse transforms for visible nodes', () {
    final scene = _scene([
      Node.group(
        id: 'group',
        xf: (Affine2D.translation(80, 20) * Affine2D.rotation(0.25)),
        children: [
          _text(
            xf: (Affine2D.translation(15, -10) * Affine2D.rotation(-0.4) * Affine2D.scale(1.5, 0.7)),
          ),
        ],
      ),
    ]);

    final computed = computeScene(scene, _services());

    final geometry = EditorGeometryIndex.fromComputed(computed);

    expect(
      geometry.inverseWorldById.keys,
      containsAll(computed.worldById.keys),
    );

    final point = geometry.inverseWorldById['text']!.transformPoint(
      computed.worldById['text']!.transformPoint(const Vec2(7, -3)));

    expect(point.x, closeTo(7, 1e-8));
    expect(point.y, closeTo(-3, 1e-8));
  });

  test('counter-rotated groups retain tight descendant world unions', () {
    const expected = Rect2D(-50, -10, 50, 10);

    final scene = _scene([
      Node.group(
        id: 'outer',
        xf: Affine2D.rotation(math.pi / 4),
        children: [
          Node.group(
            id: 'inner',
            xf: Affine2D.rotation(-math.pi / 4),
            children: [_text()],
          ),
        ],
      ),
    ]);

    final computed = computeScene(scene, _services());

    final geometry = EditorGeometryIndex.fromComputed(computed);

    for (final id in ['text', 'inner', 'outer']) {
      _expectRect(geometry.layoutBoundsWorldById[id], expected);
    }
  });
  test('singular geometry retains bounds but has no picking inverse', () {
    final scene = _scene([Node.group(id: 'flat', xf: Affine2D.scale(0, 1), children: [_text()])]);
    final computed = computeScene(scene, _services());
    final geometry = EditorGeometryIndex.fromComputed(computed);
    expect(geometry.inverseWorldById, isEmpty);
    expect(geometry.layoutBoundsWorldById.keys, containsAll(['flat', 'text']));
    expect(geometry.layoutBoundsWorldById['text']!.width, 0);
  });

}
