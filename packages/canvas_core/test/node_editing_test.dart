import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

Node _text({
  String id = 'text',
  String? name,
  bool hidden = false,
  bool locked = false,
  Transform2D xf = const Transform2D(),
}) {
  return Node.text(
    id: id,
    name: name,
    hidden: hidden,
    locked: locked,
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
      final locked = hidden.withLocked(true) as GroupNode;

      expect(locked.id, 'group');
      expect(locked.name, 'Renamed');
      expect(locked.xf, nextXf);
      expect(locked.hidden, isTrue);
      expect(locked.locked, isTrue);
      expect(locked.children, hasLength(1));
      expect(identical(locked.children.single, child), isTrue);
    });
  });
}
