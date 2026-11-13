import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:test/test.dart';

void main() {
  group('TextNode letterSpacing JSON', () {
    test('decodes an integer JSON number as a double', () {
      final data =
          Node.fromJson({
                'type': 'text',
                'id': 'text',
                'text': 'Hello',
                'fontFamily': 'Inter',
                'fontWeight': 400,
                'fontSize': 16.0,
                'letterSpacing': 2,
              })
              as TextNode;

      expect(data.letterSpacing, 2.0);
    });

    test('preserves fractional letter spacing', () {
      final data =
          Node.fromJson({
                'type': 'text',
                'id': 'text',
                'text': 'Hello',
                'fontFamily': 'Inter',
                'fontWeight': 400,
                'fontSize': 16.0,
                'letterSpacing': 1.25,
              })
              as TextNode;

      expect(data.letterSpacing, 1.25);
    });

    test('round-trips fractional letter spacing', () {
      const original = TextNode(
        id: 'text',
        text: 'Hello',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 1.25,
      );

      final restored = Node.fromJson(original.toJson()) as TextNode;

      expect(restored.letterSpacing, 1.25);
    });

    test('defaults missing letter spacing to zero', () {
      final data =
          Node.fromJson({
                'type': 'text',
                'id': 'text',
                'text': 'Hello',
                'fontFamily': 'Inter',
                'fontWeight': 400,
                'fontSize': 16.0,
              })
              as TextNode;

      expect(data.letterSpacing, 0.0);
    });
  });
}
