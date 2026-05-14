// Path: test/node_name_json_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

const _textData = TextData(
  text: 'Hello',
  fontFamily: 'Inter',
  fontWeight: 700,
  fontSize: 24,
  letterSpacing: 0,
  fill: CanvasFill.solid(0xFF111111),
  shadowOffset: 0,
);

void main() {
  group('Node name JSON', () {
    test('text node name round-trips through JSON', () {
      const node = Node.text(id: 'text-1', name: 'Hero Title', data: _textData);

      final json = node.toJson();
      expect(json['name'], 'Hero Title');

      final decoded = Node.fromJson(json);
      expect(decoded.name, 'Hero Title');
      expect(decoded, isA<TextNode>());
    });

    test('missing name decodes as null', () {
      final json = <String, dynamic>{
        'runtimeType': 'text',
        'id': 'text-1',
        'data': _textData.toJson(),
      };

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
      const node = Node.text(id: 'text-1', data: _textData);

      final renamed = node.withName('   ');

      expect(renamed.name, isNull);
    });

    test('withName trims surrounding whitespace', () {
      const node = Node.text(id: 'text-1', data: _textData);

      final renamed = node.withName('  Layer Name  ');

      expect(renamed.name, 'Layer Name');
    });

    test('withName truncates names to 80 characters', () {
      const node = Node.text(id: 'text-1', data: _textData);

      final long = 'x' * 120;
      final renamed = node.withName(long);

      expect(renamed.name, hasLength(80));
    });
  });
}
