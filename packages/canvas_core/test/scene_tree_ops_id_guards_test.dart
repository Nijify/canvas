// Path: packages/canvas_core/test/scene_tree_ops_id_guards_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

const _textData = TextData(
  text: 't',
  fontFamily: 'Inter',
  fontWeight: 400,
  fontSize: 12,
);

Node _text(String id, {String? name}) {
  return Node.text(id: id, name: name, data: _textData);
}

CanvasSceneDocument _scene(List<Node> children) {
  return CanvasSceneDocument(
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: children,
  );
}

void main() {
  group('SceneTreeOps.addNode ID guards', () {
    test('rejects a root ID that already exists in the document', () {
      final doc = _scene(<Node>[_text('existing')]);

      expect(
        () => SceneTreeOps.addNode(doc, _text('existing')),
        throwsArgumentError,
      );

      expect(doc.children.single.id, 'existing');
    });

    test('rejects a descendant ID that already exists in the document', () {
      final doc = _scene(<Node>[_text('existing')]);

      final incoming = Node.group(
        id: 'new-group',
        children: <Node>[_text('existing')],
      );

      expect(() => SceneTreeOps.addNode(doc, incoming), throwsArgumentError);
    });

    test('rejects duplicate IDs inside the incoming subtree', () {
      final doc = _scene(const <Node>[]);

      final incoming = Node.group(
        id: 'new-group',
        children: <Node>[_text('duplicate'), _text('duplicate')],
      );

      expect(() => SceneTreeOps.addNode(doc, incoming), throwsArgumentError);
    });

    test('rejects a blank ID anywhere in the incoming subtree', () {
      final doc = _scene(const <Node>[]);

      final incoming = Node.group(
        id: 'new-group',
        children: <Node>[_text('   ')],
      );

      expect(() => SceneTreeOps.addNode(doc, incoming), throwsArgumentError);
    });

    test('invalid parent remains a no-op before incoming ID validation', () {
      final doc = _scene(<Node>[_text('leaf-parent')]);

      final invalidIncoming = Node.group(
        id: 'new-group',
        children: <Node>[_text('duplicate'), _text('duplicate')],
      );

      final missingParent = SceneTreeOps.addNode(
        doc,
        invalidIncoming,
        parentId: 'missing',
      );

      final leafParent = SceneTreeOps.addNode(
        doc,
        invalidIncoming,
        parentId: 'leaf-parent',
      );

      expect(missingParent, same(doc));
      expect(leafParent, same(doc));
    });

    test('accepts a valid nested addition and keeps the scene valid', () {
      final doc = _scene(<Node>[_text('existing')]);

      final incoming = Node.group(
        id: 'new-group',
        children: <Node>[
          _text('new-child'),
          Node.group(id: 'nested', children: <Node>[_text('nested-child')]),
        ],
      );

      final updated = SceneTreeOps.addNode(doc, incoming);

      expect(findById(updated, 'new-group'), isA<GroupNode>());
      expect(findById(updated, 'new-child'), isNotNull);
      expect(findById(updated, 'nested-child'), isNotNull);
      expect(validateCanvasSceneDocument(updated), isEmpty);
    });
  });

  group('replaceById ID guards', () {
    test('requires the replacement root ID to match the target', () {
      final doc = _scene(<Node>[_text('target')]);

      expect(
        () => replaceById(doc, 'target', _text('different')),
        throwsArgumentError,
      );
    });

    test('missing target remains a no-op before replacement validation', () {
      final doc = _scene(<Node>[_text('existing')]);

      final updated = replaceById(doc, 'missing', _text('different'));

      expect(updated, same(doc));
    });

    test('rejects a descendant collision outside the replaced subtree', () {
      final group =
          Node.group(id: 'group', children: <Node>[_text('inside')])
              as GroupNode;

      final doc = _scene(<Node>[group, _text('outside')]);

      final replacement = group.copyWith(
        children: <Node>[_text('inside'), _text('outside')],
      );

      expect(() => replaceById(doc, 'group', replacement), throwsArgumentError);
    });

    test('rejects duplicate IDs inside a replacement subtree', () {
      final group =
          Node.group(id: 'group', children: <Node>[_text('old-child')])
              as GroupNode;

      final doc = _scene(<Node>[group]);

      final replacement = group.copyWith(
        children: <Node>[_text('duplicate'), _text('duplicate')],
      );

      expect(() => replaceById(doc, 'group', replacement), throwsArgumentError);
    });

    test('rejects a blank descendant ID in a replacement subtree', () {
      final group =
          Node.group(id: 'group', children: <Node>[_text('old-child')])
              as GroupNode;

      final doc = _scene(<Node>[group]);

      final replacement = group.copyWith(children: <Node>[_text('   ')]);

      expect(() => replaceById(doc, 'group', replacement), throwsArgumentError);
    });

    test('structural replacement may retain IDs from the old subtree', () {
      final first = _text('first');
      final second = _text('second');

      final group =
          Node.group(id: 'group', children: <Node>[first, second]) as GroupNode;

      final doc = _scene(<Node>[group, _text('outside')]);

      final replacement = group.copyWith(children: <Node>[second, first]);

      final updated = replaceById(doc, 'group', replacement);

      final updatedGroup = findById(updated, 'group') as GroupNode;

      expect(updatedGroup.children.map((node) => node.id), <String>[
        'second',
        'first',
      ]);

      expect(validateCanvasSceneDocument(updated), isEmpty);
    });

    test('accepts ordinary group property updates', () {
      final group = Node.group(id: 'group', children: <Node>[_text('child')]);

      final doc = _scene(<Node>[group]);

      final updated = replaceById(
        doc,
        'group',
        group.copyWith(name: 'Renamed group'),
      );

      final updatedGroup = findById(updated, 'group') as GroupNode;

      expect(updatedGroup.name, 'Renamed group');
      expect(updatedGroup.children.single.id, 'child');
      expect(validateCanvasSceneDocument(updated), isEmpty);
    });

    test('accepts ordinary leaf property updates', () {
      final leaf = _text('leaf');
      final doc = _scene(<Node>[leaf]);

      final updated = replaceById(
        doc,
        'leaf',
        (leaf as TextNode).copyWith(name: 'Renamed leaf'),
      );

      final updatedLeaf = findById(updated, 'leaf') as TextNode;

      expect(updatedLeaf.name, 'Renamed leaf');
      expect(validateCanvasSceneDocument(updated), isEmpty);
    });
  });
}
