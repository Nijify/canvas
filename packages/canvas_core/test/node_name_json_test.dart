// Path: test/node_name_json_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

const _textNode = TextNode(
  id: 'text-1',
  text: 'Hello',
  fontFamily: 'Inter',
  fontWeight: 700,
  fontSize: 24,
  letterSpacing: 0,
  appearance: CanvasAppearance(foreground: CanvasFill.solid(0xFF111111)),
);

void main() {
  group('Node name JSON', () {
    test('text node name round-trips through JSON', () {
      final node = _textNode.copyWith(id: 'text-1', name: 'Hero Title');

      final json = node.toJson();
      expect(json['name'], 'Hero Title');

      final decoded = Node.fromJson(json);
      expect(decoded.name, 'Hero Title');
      expect(decoded, isA<TextNode>());
    });

    test('missing name decodes as null', () {
      final json = _textNode.toJson();
      expect(json, isNot(contains('name')));

      final decoded = Node.fromJson(json);

      expect(decoded.name, isNull);
      expect(decoded, isA<TextNode>());
    });

    test('group node name round-trips through JSON', () {
      const node = Node.group(
        id: 'group-1',
        name: 'Header Group',
        children: <Node>[],
      );

      final json = node.toJson();
      expect(json['name'], 'Header Group');

      final decoded = Node.fromJson(json);
      expect(decoded.name, 'Header Group');
      expect(decoded, isA<GroupNode>());
    });

    test('withName normalizes empty names to null', () {
      const node = _textNode;

      final renamed = node.withName('   ');

      expect(renamed.name, isNull);
    });

    test('withName trims surrounding whitespace', () {
      const node = _textNode;

      final renamed = node.withName('  Layer Name  ');

      expect(renamed.name, 'Layer Name');
    });

    test('withName truncates names to 80 characters', () {
      const node = _textNode;

      final long = 'x' * 120;
      final renamed = node.withName(long);

      expect(renamed.name, hasLength(80));
    });
  });
}
