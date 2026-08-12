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

void main() {
  test('duplicateSubtree clones nested structure with new IDs', () {
    final nested = Node.group(id: 'nested', children: <Node>[_text('b')]);
    final group = Node.group(id: 'g', children: <Node>[_text('a'), nested]);
    final scene = CanvasSceneDocument(
      backgroundFill: const CanvasFill.none(),
      backgroundOpacity: 1.0,
      children: <Node>[group],
    );

    final result = SceneTreeOps.duplicateSubtree(
      scene,
      'g',
      idGen: (oldId) => '${oldId}_copy',
    );

    expect(result.primaryId, 'g_copy');
    expect(result.idMap, <String, String>{
      'g': 'g_copy',
      'a': 'a_copy',
      'nested': 'nested_copy',
      'b': 'b_copy',
    });
    expect(result.createdIds, <String>[
      'g_copy',
      'a_copy',
      'nested_copy',
      'b_copy',
    ]);

    final original = findById(result.doc, 'g') as GroupNode;
    final duplicate = findById(result.doc, 'g_copy') as GroupNode;
    final duplicateNested = findById(result.doc, 'nested_copy') as GroupNode;

    expect(original.children.map((node) => node.id), <String>['a', 'nested']);
    expect(duplicate.children.map((node) => node.id), <String>[
      'a_copy',
      'nested_copy',
    ]);
    expect(duplicateNested.children.single.id, 'b_copy');
  });
}
