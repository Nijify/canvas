// Path: packages/canvas_core/test/scene_tree_ops_transform_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

const _textData = TextData(
  text: 'Hello',
  fontFamily: 'Inter',
  fontWeight: 400,
  fontSize: 16,
);

CanvasSceneDocument _scene() {
  return const CanvasSceneDocument(
    backgroundFill: CanvasFill.none(),
    backgroundOpacity: 1,
    children: <Node>[
      Node.text(
        id: 'node',
        xf: Transform2D(
          position: Vec2(1, 2),
          rotationRad: 0.5,
          scale: Vec2(2, 3),
        ),
        data: _textData,
      ),
    ],
  );
}

Transform2D _xf(CanvasSceneDocument doc) {
  return findById(doc, 'node')!.xf;
}

void main() {
  group('SceneTreeOps transform helpers', () {
    test('replaceNodeXf replaces the node transform', () {
      final doc = _scene();

      const nextXf = Transform2D(
        position: Vec2(10, 20),
        rotationRad: 1,
        scale: Vec2(4, 5),
      );

      final next = SceneTreeOps.replaceNodeXf(doc, 'node', nextXf);

      expect(_xf(next), nextXf);
    });

    test('translate updates position', () {
      final next = SceneTreeOps.translate(_scene(), 'node', const Vec2(4, -1));

      expect(_xf(next).position, const Vec2(5, 1));
      expect(_xf(next).rotationRad, 0.5);
      expect(_xf(next).scale, const Vec2(2, 3));
    });

    test('rotate updates rotation', () {
      final next = SceneTreeOps.rotate(_scene(), 'node', 0.25);

      expect(_xf(next).position, const Vec2(1, 2));
      expect(_xf(next).rotationRad, 0.75);
      expect(_xf(next).scale, const Vec2(2, 3));
    });

    test('uniformScale updates both scale axes', () {
      final next = SceneTreeOps.uniformScale(_scene(), 'node', 2);

      expect(_xf(next).position, const Vec2(1, 2));
      expect(_xf(next).rotationRad, 0.5);
      expect(_xf(next).scale, const Vec2(4, 6));
    });

    test('transform helpers preserve missing-node behavior', () {
      final doc = _scene();

      expect(
        SceneTreeOps.replaceNodeXf(
          doc,
          'missing',
          const Transform2D(position: Vec2(10, 20)),
        ),
        same(doc),
      );

      expect(
        SceneTreeOps.translate(doc, 'missing', const Vec2(10, 20)),
        same(doc),
      );

      expect(SceneTreeOps.rotate(doc, 'missing', 1), same(doc));

      expect(SceneTreeOps.uniformScale(doc, 'missing', 2), same(doc));
    });
  });
}
