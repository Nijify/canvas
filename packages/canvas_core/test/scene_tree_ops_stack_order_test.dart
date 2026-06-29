// Path: test/scene_tree_ops_stack_order_test.dart

import 'package:test/test.dart';
import 'package:canvas_core/canvas_core_runtime.dart';

Node _text(String id) => Node.text(
  id: id,
  data: const TextData(
    text: 't',
    fontFamily: 'Inter',
    fontWeight: 400,
    fontSize: 12,
  ),
);

CanvasSceneDocument _scene({required List<Node> children}) {
  return CanvasSceneDocument(
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: children,
  );
}

List<String> _rootIds(CanvasSceneDocument doc) {
  return [for (final n in doc.children) n.id];
}

List<String> _groupChildIds(CanvasSceneDocument doc, String groupId) {
  final group = findById(doc, groupId) as GroupNode;
  return [for (final n in group.children) n.id];
}

void main() {
  group('SceneTreeOps stack-order helpers', () {
    test('bringToFront/sendToBack move root elements to stack extremes', () {
      final doc = _scene(children: [_text('a'), _text('b'), _text('c')]);

      final front = SceneTreeOps.bringToFront(doc, 'a');
      expect(_rootIds(front), ['b', 'c', 'a']);

      final back = SceneTreeOps.sendToBack(doc, 'c');
      expect(_rootIds(back), ['c', 'a', 'b']);
    });

    test(
      'bringForward/sendBackward move root elements by one sibling step',
      () {
        final doc = _scene(children: [_text('a'), _text('b'), _text('c')]);

        final forward = SceneTreeOps.bringForward(doc, 'a');
        expect(_rootIds(forward), ['b', 'a', 'c']);

        final backward = SceneTreeOps.sendBackward(doc, 'c');
        expect(_rootIds(backward), ['a', 'c', 'b']);
      },
    );

    test('stack-order operations respect group boundaries', () {
      final group = Node.group(
        id: 'g',
        children: [_text('a'), _text('b'), _text('c')],
      );

      final doc = _scene(
        children: [_text('root-before'), group, _text('root-after')],
      );

      final updated = SceneTreeOps.sendBackward(doc, 'c');

      expect(_rootIds(updated), ['root-before', 'g', 'root-after']);
      expect(_groupChildIds(updated, 'g'), ['a', 'c', 'b']);
    });

    test('duplicate inserts immediately above original', () {
      final doc = _scene(children: [_text('a'), _text('b'), _text('c')]);

      final res = SceneTreeOps.duplicateSubtree(
        doc,
        'b',
        idGen: (oldId) => '${oldId}_copy',
      );

      expect(res.primaryId, 'b_copy');
      expect(_rootIds(res.doc), ['a', 'b', 'b_copy', 'c']);
    });

    test('addNode defaults to frontmost position', () {
      final doc = _scene(children: [_text('a'), _text('b')]);

      final updated = SceneTreeOps.addNode(doc, _text('c'));

      expect(_rootIds(updated), ['a', 'b', 'c']);
    });

    test('addNode can insert at explicit root index', () {
      final doc = _scene(children: [_text('a'), _text('c')]);

      final updated = SceneTreeOps.addNode(doc, _text('b'), index: 1);

      expect(_rootIds(updated), ['a', 'b', 'c']);
    });

    test('moveSubtree within same parent uses final target index', () {
      final doc = _scene(
        children: [_text('a'), _text('b'), _text('c'), _text('d')],
      );

      final updated = SceneTreeOps.moveSubtree(doc, 'b', toIndex: 3);

      expect(_rootIds(updated), ['a', 'c', 'd', 'b']);
    });

    test('moveSubtree can move root into group at explicit index', () {
      final group = Node.group(id: 'g', children: [_text('x'), _text('z')]);

      final doc = _scene(children: [_text('a'), group]);

      final updated = SceneTreeOps.moveSubtree(
        doc,
        'a',
        newParentId: 'g',
        toIndex: 1,
      );

      expect(_rootIds(updated), ['g']);
      expect(_groupChildIds(updated, 'g'), ['x', 'a', 'z']);
    });
  });
}
