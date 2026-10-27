import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

Node _node(String id, Affine2D xf) => Node.group(id: id, xf: xf, children: []);
CanvasSceneDocument _scene() => CanvasSceneDocument(children: [
  Node.group(id: 'parent', xf: Affine2D(2, .5, 1, -3, 40, 20), children: [
    _node('child', Affine2D(1, 0, .4, 2, 3, 5)),
  ]),
  _node('target', Affine2D(1, 1, -.5, 2, -20, 50)),
]);
void _close(Affine2D actual, Affine2D expected) {
  for (var i = 0; i < 6; i++) expect(actual.toJson()[i], closeTo(expected.toJson()[i], 1e-9));
}
void main() {
  test('local, parent and world deltas share explicit composition rules', () {
    final doc = _scene();
    final local = findById(doc, 'child')!.xf;
    final parent = findById(doc, 'parent')!.xf;
    final delta = affineAround(const Vec2(10, 20), Affine2D.rotation(.4));
    for (final space in TransformSpace.values) {
      final next = SceneTreeOps.composeDelta(doc, 'child', delta, space: space);
      final expected = switch (space) {
        TransformSpace.local => local * delta,
        TransformSpace.parent => delta * local,
        TransformSpace.world => parent.tryInverse()! * delta * parent * local,
      };
      _close(findById(next, 'child')!.xf, expected);
    }
  });
  test('world preserving reparent retains shear and reflection', () {
    final doc = _scene();
    final world = worldTransformOf(doc, 'child')!;
    final moved = SceneTreeOps.moveSubtree(doc, 'child', newParentId: 'target',
      preservation: TransformPreservation.world);
    _close(worldTransformOf(moved, 'child')!, world);
    final local = SceneTreeOps.moveSubtree(doc, 'child',
      preservation: TransformPreservation.local);
    expect(findById(local, 'child')!.xf, findById(doc, 'child')!.xf);
  });
  test('singular target rejects world preservation without changing source', () {
    final doc = CanvasSceneDocument(children: [
      _node('child', const Affine2D.identity()), _node('target', Affine2D.scale(0, 1)),
    ]);
    expect(() => SceneTreeOps.moveSubtree(doc, 'child', newParentId: 'target',
      preservation: TransformPreservation.world), throwsStateError);
    expect(doc.children.map((n) => n.id), ['child', 'target']);
  });
  test('world delta works for singular node under invertible parent', () {
    final doc = CanvasSceneDocument(children: [_node('flat', Affine2D.scale(0, 1))]);
    final next = SceneTreeOps.translate(doc, 'flat', const Vec2(4, 5), space: TransformSpace.world);
    expect(findById(next, 'flat')!.xf.transformPoint(Vec2.zero), const Vec2(4, 5));
  });
  test('missing node and equal replacement are unchanged', () {
    final doc = _scene();
    expect(SceneTreeOps.replaceNodeXf(doc, 'child', findById(doc, 'child')!.xf), same(doc));
    expect(SceneTreeOps.translate(doc, 'missing', const Vec2(1, 2)), same(doc));
  });
}
