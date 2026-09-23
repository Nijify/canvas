// Path: packages/canvas_editor_flutter/test/interaction/geometry/editor_geometry_index_test.dart

import 'dart:math' as math;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/interaction/geometry/editor_geometry_index.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

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

Node _text({String id = 'text', Transform2D xf = const Transform2D()}) =>
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
        xf: const Transform2D(
          position: Vec2(30, 40),
          rotationRad: 0.35,
          scale: Vec2(1.5, 0.75),
        ),
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
        xf: const Transform2D(position: Vec2(80, 20), rotationRad: 0.25),
        children: [
          _text(
            xf: const Transform2D(
              position: Vec2(15, -10),
              rotationRad: -0.4,
              scale: Vec2(1.5, 0.7),
            ),
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

    final point = vm.Vector3(7, -3, 0);

    computed.worldById['text']!.transform3(point);
    geometry.inverseWorldById['text']!.transform3(point);

    expect(point.x, closeTo(7, 1e-8));
    expect(point.y, closeTo(-3, 1e-8));
  });

  test('counter-rotated groups retain tight descendant world unions', () {
    const expected = Rect2D(-50, -10, 50, 10);

    final scene = _scene([
      Node.group(
        id: 'outer',
        xf: Transform2D(rotationRad: math.pi / 4),
        children: [
          Node.group(
            id: 'inner',
            xf: Transform2D(rotationRad: -math.pi / 4),
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
}
