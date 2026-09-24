// Path: packages/canvas_core/test/node_editing_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

Node _text({
  String id = 'text',
  String? name,
  bool hidden = false,
  Transform2D xf = const Transform2D(),
}) {
  return Node.text(
    id: id,
    name: name,
    hidden: hidden,
    xf: xf,
    data: const TextData(
      text: 'Hello',
      fontFamily: 'Inter',
      fontWeight: 400,
      fontSize: 16,
    ),
  );
}

void main() {
  group('NodeEditingX', () {
    test('withName trims, normalizes blank names, and caps length', () {
      final node = _text(name: 'Original');
      final longName = List<String>.filled(81, 'x').join();
      final cappedName = List<String>.filled(80, 'x').join();

      expect(node.withName('  Headline  ').name, 'Headline');
      expect(node.withName('   ').name, isNull);
      expect(node.withName(longName).name, cappedName);

      final eightyEmoji = List<String>.filled(80, '😀').join();
      final eightyOneEmoji = List<String>.filled(81, '😀').join();

      expect(node.withName(eightyEmoji).name, eightyEmoji);
      expect(
        node.withName(eightyOneEmoji).name,
        List<String>.filled(80, '😀').join(),
      );
    });

    test('safe edits preserve node identity and tree structure', () {
      final child = _text(id: 'child');
      final group = Node.group(
        id: 'group',
        name: 'Group',
        children: <Node>[child],
      );

      const nextXf = Transform2D(position: Vec2(12, 34));

      final renamed = group.withName('Renamed') as GroupNode;
      final moved = renamed.withXf(nextXf) as GroupNode;
      final hidden = moved.withHidden(true) as GroupNode;

      expect(hidden.id, 'group');
      expect(hidden.name, 'Renamed');
      expect(hidden.xf, nextXf);
      expect(hidden.hidden, isTrue);
      expect(hidden.children, hasLength(1));
      expect(identical(hidden.children.single, child), isTrue);
    });
  });
}
