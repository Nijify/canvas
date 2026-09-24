// Path: packages/canvas_core/test/scene_tree_ops_duplication_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

Node _text(String id) => Node.text(
  id: id,
  data: const TextData(
    text: 't',
    fontFamily: 'Inter',
    fontWeight: 400,
    fontSize: 12,
  ),
);

CanvasSceneDocument _scene(List<Node> children) {
  return CanvasSceneDocument(
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: children,
  );
}

List<String> _rootIds(CanvasSceneDocument doc) {
  return [for (final node in doc.children) node.id];
}

List<String> _allIds(CanvasSceneDocument doc) {
  final ids = <String>[];

  visitSceneNodes(doc, includeHidden: true, visit: (node) => ids.add(node.id));

  return ids;
}

void main() {
  group('SceneTreeOps.duplicateSubtree', () {
    test('clones nested structure with deterministic mapped IDs', () {
      final nested = Node.group(id: 'nested', children: <Node>[_text('b')]);
      final group = Node.group(
        id: 'g',
        xf: const Transform2D(position: Vec2(10, 20)),
        children: <Node>[_text('a'), nested],
      );
      final scene = _scene(<Node>[group]);

      final result = SceneTreeOps.duplicateSubtree(scene, 'g');

      expect(result.primaryId, 'g_copy_1');
      expect(result.idMap, <String, String>{
        'g': 'g_copy_1',
        'a': 'a_copy_2',
        'nested': 'nested_copy_3',
        'b': 'b_copy_4',
      });

      expect(_rootIds(result.doc), <String>['g', 'g_copy_1']);

      final original = findById(result.doc, 'g') as GroupNode;
      final duplicate = findById(result.doc, 'g_copy_1') as GroupNode;
      final duplicateNested =
          findById(result.doc, 'nested_copy_3') as GroupNode;

      expect(original.children.map((node) => node.id), <String>['a', 'nested']);

      expect(duplicate.children.map((node) => node.id), <String>[
        'a_copy_2',
        'nested_copy_3',
      ]);

      expect(duplicateNested.children.single.id, 'b_copy_4');

      // Only the duplicate root receives the standard position shift.
      expect(duplicate.xf.position, const Vec2(26, 36));

      expect(validateCanvasSceneDocument(result.doc), isEmpty);
    });

    test(
      'can duplicate the same node repeatedly and then duplicate a copy',
      () {
        final scene = _scene(<Node>[_text('t')]);

        final first = SceneTreeOps.duplicateSubtree(scene, 't');
        expect(first.primaryId, 't_copy_1');

        final second = SceneTreeOps.duplicateSubtree(first.doc, 't');
        expect(second.primaryId, 't_copy_2');

        final third = SceneTreeOps.duplicateSubtree(
          second.doc,
          first.primaryId!,
        );
        expect(third.primaryId, 't_copy_1_copy_1');

        expect(_rootIds(third.doc), <String>[
          't',
          't_copy_2',
          't_copy_1',
          't_copy_1_copy_1',
        ]);

        final ids = _allIds(third.doc);
        expect(ids.toSet(), hasLength(ids.length));

        expect(validateCanvasSceneDocument(third.doc), isEmpty);
      },
    );

    test('skips copy-style IDs already used elsewhere in the document', () {
      final group = Node.group(id: 'g', children: <Node>[_text('a')]);

      final scene = _scene(<Node>[_text('g_copy_1'), _text('a_copy_3'), group]);

      final result = SceneTreeOps.duplicateSubtree(scene, 'g');

      expect(result.primaryId, 'g_copy_2');
      expect(result.idMap, <String, String>{'g': 'g_copy_2', 'a': 'a_copy_4'});

      final duplicate = findById(result.doc, 'g_copy_2') as GroupNode;
      expect(duplicate.children.single.id, 'a_copy_4');

      expect(validateCanvasSceneDocument(result.doc), isEmpty);
    });

    test('same input document and operation produce the same IDs', () {
      final scene = _scene(<Node>[
        _text('g_copy_1'),
        Node.group(
          id: 'g',
          children: <Node>[
            _text('a'),
            Node.group(id: 'nested', children: <Node>[_text('b')]),
          ],
        ),
      ]);

      final first = SceneTreeOps.duplicateSubtree(scene, 'g');
      final second = SceneTreeOps.duplicateSubtree(scene, 'g');

      expect(first.primaryId, second.primaryId);
      expect(first.idMap, second.idMap);
      expect(_allIds(first.doc), _allIds(second.doc));

      expect(validateCanvasSceneDocument(first.doc), isEmpty);
      expect(validateCanvasSceneDocument(second.doc), isEmpty);
    });
  });
}
