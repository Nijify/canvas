// Path: test/text_data_letter_spacing_json_test.dart

import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:test/test.dart';

void main() {
  group('TextData letterSpacing JSON', () {
    test('decodes an integer JSON number as a double', () {
      final data = TextData.fromJson({
        'text': 'Hello',
        'fontFamily': 'Inter',
        'fontWeight': 400,
        'fontSize': 16.0,
        'letterSpacing': 2,
      });

      expect(data.letterSpacing, 2.0);
    });

    test('preserves fractional letter spacing', () {
      final data = TextData.fromJson({
        'text': 'Hello',
        'fontFamily': 'Inter',
        'fontWeight': 400,
        'fontSize': 16.0,
        'letterSpacing': 1.25,
      });

      expect(data.letterSpacing, 1.25);
    });

    test('round-trips fractional letter spacing', () {
      const original = TextData(
        text: 'Hello',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 1.25,
      );

      final restored = TextData.fromJson(original.toJson());

      expect(restored.letterSpacing, 1.25);
    });

    test('defaults missing letter spacing to zero', () {
      final data = TextData.fromJson({
        'text': 'Hello',
        'fontFamily': 'Inter',
        'fontWeight': 400,
        'fontSize': 16.0,
      });

      expect(data.letterSpacing, 0.0);
    });
  });
}
